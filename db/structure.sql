SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ajustar_stock(bigint, bigint, numeric, text, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ajustar_stock(p_material_id bigint, p_warehouse_id bigint, p_delta numeric, p_operacion text, p_movement_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_anterior numeric;
  v_nueva numeric;
BEGIN
  IF p_delta = 0 THEN
    RETURN;
  END IF;

  INSERT INTO stocks (material_id, warehouse_id, quantity, created_at, updated_at)
  VALUES (p_material_id, p_warehouse_id, 0, NOW(), NOW())
  ON CONFLICT (material_id, warehouse_id) DO NOTHING;

  SELECT quantity INTO v_anterior
  FROM stocks
  WHERE material_id = p_material_id AND warehouse_id = p_warehouse_id
  FOR UPDATE;

  v_nueva := v_anterior + p_delta;

  IF v_nueva < 0 THEN
    RAISE EXCEPTION 'Stock insuficiente: hay % y se requieren %', v_anterior, -p_delta
      USING ERRCODE = 'check_violation';
  END IF;

  UPDATE stocks
  SET quantity = v_nueva, updated_at = NOW()
  WHERE material_id = p_material_id AND warehouse_id = p_warehouse_id;

  INSERT INTO inventario_auditoria (movement_id, material_id, warehouse_id, operacion, cantidad_anterior, cantidad_nueva)
  VALUES (p_movement_id, p_material_id, p_warehouse_id, p_operacion, v_anterior, v_nueva);
END;
$$;


--
-- Name: aplicar_movimiento_a_stock(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.aplicar_movimiento_a_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM ajustar_stock(NEW.material_id, NEW.warehouse_id, efecto_movimiento(NEW.movement_type, NEW.quantity), TG_OP, NEW.id);
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM ajustar_stock(OLD.material_id, OLD.warehouse_id, -efecto_movimiento(OLD.movement_type, OLD.quantity), TG_OP, OLD.id);
  ELSIF OLD.material_id = NEW.material_id AND OLD.warehouse_id = NEW.warehouse_id THEN
    PERFORM ajustar_stock(NEW.material_id, NEW.warehouse_id, efecto_movimiento(NEW.movement_type, NEW.quantity) - efecto_movimiento(OLD.movement_type, OLD.quantity), TG_OP, NEW.id);
  ELSE
    PERFORM ajustar_stock(OLD.material_id, OLD.warehouse_id, -efecto_movimiento(OLD.movement_type, OLD.quantity), TG_OP, OLD.id);
    PERFORM ajustar_stock(NEW.material_id, NEW.warehouse_id, efecto_movimiento(NEW.movement_type, NEW.quantity), TG_OP, NEW.id);
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: efecto_movimiento(text, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.efecto_movimiento(p_tipo text, p_cantidad numeric) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE p_tipo WHEN 'salida' THEN -p_cantidad ELSE p_cantidad END;
$$;


--
-- Name: nivel_inventario(bigint, bigint, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nivel_inventario(p_material_id bigint, p_warehouse_id bigint DEFAULT NULL::bigint, p_hasta timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  v_nivel numeric;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM materials WHERE id = p_material_id) THEN
    RAISE EXCEPTION 'El material % no existe', p_material_id USING ERRCODE = 'no_data_found';
  END IF;

  SELECT COALESCE(SUM(CASE mv.movement_type WHEN 'salida' THEN -mv.quantity ELSE mv.quantity END), 0)
  INTO v_nivel
  FROM movements mv
  WHERE mv.material_id = p_material_id
    AND (p_warehouse_id IS NULL OR mv.warehouse_id = p_warehouse_id)
    AND (p_hasta IS NULL OR mv.created_at <= p_hasta);

  RETURN v_nivel;
END;
$$;


--
-- Name: niveles_inventario(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.niveles_inventario(p_warehouse_id bigint DEFAULT NULL::bigint) RETURNS TABLE(material_id bigint, sku text, material text, almacen_id bigint, almacen text, entradas numeric, salidas numeric, ajustes numeric, nivel numeric, stock_registrado numeric, diferencia numeric)
    LANGUAGE sql STABLE
    AS $$
  SELECT
    mt.id,
    mt.sku::text,
    mt.name::text,
    w.id,
    w.name::text,
    COALESCE(SUM(mv.quantity) FILTER (WHERE mv.movement_type = 'entrada'), 0),
    COALESCE(SUM(mv.quantity) FILTER (WHERE mv.movement_type = 'salida'), 0),
    COALESCE(SUM(mv.quantity) FILTER (WHERE mv.movement_type = 'ajuste'), 0),
    SUM(CASE mv.movement_type WHEN 'salida' THEN -mv.quantity ELSE mv.quantity END),
    COALESCE(s.quantity, 0),
    SUM(CASE mv.movement_type WHEN 'salida' THEN -mv.quantity ELSE mv.quantity END) - COALESCE(s.quantity, 0)
  FROM movements mv
  JOIN materials mt ON mt.id = mv.material_id
  JOIN warehouses w ON w.id = mv.warehouse_id
  LEFT JOIN stocks s ON s.material_id = mv.material_id AND s.warehouse_id = mv.warehouse_id
  WHERE p_warehouse_id IS NULL OR mv.warehouse_id = p_warehouse_id
  GROUP BY mt.id, mt.sku, mt.name, w.id, w.name, s.quantity
  ORDER BY mt.sku, w.name;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: inventario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventario (
    id integer NOT NULL,
    sku character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    unidad character varying(20) NOT NULL,
    cantidad numeric(12,2) DEFAULT 0 NOT NULL,
    actualizado_en timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT inventario_cantidad_check CHECK ((cantidad >= (0)::numeric))
);


--
-- Name: inventario_auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventario_auditoria (
    id bigint NOT NULL,
    movement_id bigint,
    material_id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    operacion character varying NOT NULL,
    cantidad_anterior numeric(12,2) NOT NULL,
    cantidad_nueva numeric(12,2) NOT NULL,
    usuario_bd character varying DEFAULT CURRENT_USER NOT NULL,
    registrado_en timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT inventario_auditoria_operacion_check CHECK (((operacion)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])))
);


--
-- Name: inventario_auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventario_auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventario_auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventario_auditoria_id_seq OWNED BY public.inventario_auditoria.id;


--
-- Name: inventario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventario_id_seq OWNED BY public.inventario.id;


--
-- Name: materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials (
    id bigint NOT NULL,
    sku character varying NOT NULL,
    name character varying NOT NULL,
    unit character varying NOT NULL,
    unit_cost numeric(12,2) DEFAULT 0.0 NOT NULL,
    min_stock numeric(12,2) DEFAULT 0.0 NOT NULL,
    supplier_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT materials_min_stock_check CHECK ((min_stock >= (0)::numeric)),
    CONSTRAINT materials_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);


--
-- Name: stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stocks (
    id bigint NOT NULL,
    material_id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    quantity numeric(12,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT stocks_quantity_check CHECK ((quantity >= (0)::numeric))
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id bigint NOT NULL,
    name character varying NOT NULL,
    contact_name character varying,
    phone character varying,
    email character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: warehouses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouses (
    id bigint NOT NULL,
    name character varying NOT NULL,
    location character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: inventario_materiales; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.inventario_materiales AS
 SELECT m.id AS material_id,
    m.sku,
    m.name AS material,
    m.unit AS unidad,
    sp.name AS proveedor,
    w.id AS almacen_id,
    w.name AS almacen,
    w.location AS ubicacion,
    COALESCE(s.quantity, (0)::numeric) AS cantidad,
    sum(COALESCE(s.quantity, (0)::numeric)) OVER (PARTITION BY m.id) AS stock_total,
    m.min_stock AS stock_minimo,
        CASE
            WHEN (sum(COALESCE(s.quantity, (0)::numeric)) OVER (PARTITION BY m.id) = (0)::numeric) THEN 'Sin stock'::text
            WHEN (sum(COALESCE(s.quantity, (0)::numeric)) OVER (PARTITION BY m.id) < m.min_stock) THEN 'Stock bajo'::text
            ELSE 'Disponible'::text
        END AS estado,
    round((COALESCE(s.quantity, (0)::numeric) * m.unit_cost), 2) AS valor,
    s.updated_at AS actualizado_en
   FROM (((public.materials m
     JOIN public.suppliers sp ON ((sp.id = m.supplier_id)))
     LEFT JOIN public.stocks s ON ((s.material_id = m.id)))
     LEFT JOIN public.warehouses w ON ((w.id = s.warehouse_id)));


--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;


--
-- Name: movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movements (
    id bigint NOT NULL,
    material_id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    user_id bigint NOT NULL,
    movement_type character varying NOT NULL,
    quantity numeric(12,2) NOT NULL,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT movements_quantity_check CHECK (((quantity > (0)::numeric) OR (((movement_type)::text = 'ajuste'::text) AND (quantity <> (0)::numeric)))),
    CONSTRAINT movements_type_check CHECK (((movement_type)::text = ANY ((ARRAY['entrada'::character varying, 'salida'::character varying, 'ajuste'::character varying])::text[])))
);


--
-- Name: movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movements_id_seq OWNED BY public.movements.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: stocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stocks_id_seq OWNED BY public.stocks.id;


--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    password_digest character varying NOT NULL,
    role character varying DEFAULT 'almacenista'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'almacenista'::character varying, 'supervisor'::character varying])::text[])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: warehouses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouses_id_seq OWNED BY public.warehouses.id;


--
-- Name: inventario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario ALTER COLUMN id SET DEFAULT nextval('public.inventario_id_seq'::regclass);


--
-- Name: inventario_auditoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_auditoria ALTER COLUMN id SET DEFAULT nextval('public.inventario_auditoria_id_seq'::regclass);


--
-- Name: materials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);


--
-- Name: movements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movements ALTER COLUMN id SET DEFAULT nextval('public.movements_id_seq'::regclass);


--
-- Name: stocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks ALTER COLUMN id SET DEFAULT nextval('public.stocks_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: warehouses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses ALTER COLUMN id SET DEFAULT nextval('public.warehouses_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: inventario_auditoria inventario_auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_auditoria
    ADD CONSTRAINT inventario_auditoria_pkey PRIMARY KEY (id);


--
-- Name: inventario inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_pkey PRIMARY KEY (id);


--
-- Name: inventario inventario_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_sku_key UNIQUE (sku);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: movements movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movements
    ADD CONSTRAINT movements_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: stocks stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT stocks_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);


--
-- Name: idx_movements_material_almacen_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movements_material_almacen_fecha ON public.movements USING btree (material_id, warehouse_id, created_at);


--
-- Name: index_inventario_auditoria_on_material_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventario_auditoria_on_material_id ON public.inventario_auditoria USING btree (material_id);


--
-- Name: index_inventario_auditoria_on_material_id_and_registrado_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventario_auditoria_on_material_id_and_registrado_en ON public.inventario_auditoria USING btree (material_id, registrado_en);


--
-- Name: index_inventario_auditoria_on_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventario_auditoria_on_warehouse_id ON public.inventario_auditoria USING btree (warehouse_id);


--
-- Name: index_materials_on_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_materials_on_sku ON public.materials USING btree (sku);


--
-- Name: index_materials_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_materials_on_supplier_id ON public.materials USING btree (supplier_id);


--
-- Name: index_movements_on_material_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movements_on_material_id ON public.movements USING btree (material_id);


--
-- Name: index_movements_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movements_on_user_id ON public.movements USING btree (user_id);


--
-- Name: index_movements_on_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movements_on_warehouse_id ON public.movements USING btree (warehouse_id);


--
-- Name: index_stocks_on_material_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stocks_on_material_id ON public.stocks USING btree (material_id);


--
-- Name: index_stocks_on_material_id_and_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stocks_on_material_id_and_warehouse_id ON public.stocks USING btree (material_id, warehouse_id);


--
-- Name: index_stocks_on_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stocks_on_warehouse_id ON public.stocks USING btree (warehouse_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: movements trg_movimientos_actualizan_stock; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_movimientos_actualizan_stock AFTER INSERT OR DELETE OR UPDATE OF material_id, warehouse_id, movement_type, quantity ON public.movements FOR EACH ROW EXECUTE FUNCTION public.aplicar_movimiento_a_stock();


--
-- Name: stocks fk_rails_015c017e64; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT fk_rails_015c017e64 FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: inventario_auditoria fk_rails_0629fcf08f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_auditoria
    ADD CONSTRAINT fk_rails_0629fcf08f FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: movements fk_rails_1b3d8ec724; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movements
    ADD CONSTRAINT fk_rails_1b3d8ec724 FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: inventario_auditoria fk_rails_1ec82967bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_auditoria
    ADD CONSTRAINT fk_rails_1ec82967bc FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: materials fk_rails_5df143144c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT fk_rails_5df143144c FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: stocks fk_rails_71dac01cca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT fk_rails_71dac01cca FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: movements fk_rails_b16b3af240; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movements
    ADD CONSTRAINT fk_rails_b16b3af240 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: movements fk_rails_e0f26005af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movements
    ADD CONSTRAINT fk_rails_e0f26005af FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261106142347'),
('20261105183313'),
('20261105175916'),
('20261104174659'),
('20261104174622'),
('20261104174553'),
('20261104174239'),
('20261104174144'),
('20261104174118');

