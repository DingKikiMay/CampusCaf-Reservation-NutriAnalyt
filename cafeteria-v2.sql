CREATE EXTENSION IF NOT EXISTS pgcrypto; --生成uuid

CREATE TABLE users (
  uid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uname VARCHAR(50) NOT NULL
);

CREATE TABLE ingredients (
  iid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  iname VARCHAR(50) NOT NULL,
  energy NUMERIC(10,2),          -- kcal / 100g
  protein NUMERIC(10,2),         -- g / 100g
  fat NUMERIC(10,2),             -- g / 100g
  carbohydrates NUMERIC(10,2),   -- g / 100g
  sodium NUMERIC(10,2)           -- mg / 100g
);

CREATE TABLE dishes (
  did UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dname VARCHAR(50) NOT NULL,
  price NUMERIC(10,2) NOT NULL
);

CREATE TABLE dishes_ingredients (
  did UUID NOT NULL,
  iid UUID NOT NULL,
  weight NUMERIC(10,2) NOT NULL CHECK (weight > 0), -- g

  PRIMARY KEY (did, iid),
  FOREIGN KEY (did) REFERENCES dishes(did) ON DELETE CASCADE,
  FOREIGN KEY (iid) REFERENCES ingredients(iid)
);

CREATE TABLE dish_nrv (
  did UUID PRIMARY KEY,
  energy_pct NUMERIC(6,2),
  protein_pct NUMERIC(6,2),
  fat_pct NUMERIC(6,2),
  carbohydrates_pct NUMERIC(6,2),
  sodium_pct NUMERIC(6,2),

  FOREIGN KEY (did) REFERENCES dishes(did) ON DELETE CASCADE
);

CREATE TABLE orders (
  oid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  odate DATE NOT NULL,
  meal_slot VARCHAR(10) NOT NULL
    CHECK (meal_slot IN ('lunch','dinner')),
  uid UUID NOT NULL,
  status VARCHAR(10) NOT NULL
    CHECK (status IN ('pending','confirmed','cancelled','served')),
  pickup_qr UUID,
  created_at TIMESTAMP NOT NULL DEFAULT now(),

  FOREIGN KEY (uid) REFERENCES users(uid)
);

CREATE TABLE orders_dishes (
  oid UUID NOT NULL,
  did UUID NOT NULL,
  qty INT NOT NULL CHECK (qty > 0),
  note TEXT,
  unit_price NUMERIC(10,2) NOT NULL,

  PRIMARY KEY (oid, did),
  FOREIGN KEY (oid) REFERENCES orders(oid) ON DELETE CASCADE,
  FOREIGN KEY (did) REFERENCES dishes(did)
);

CREATE TABLE preparations (
  pid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pdate DATE NOT NULL,
  iid UUID NOT NULL,
  required_g NUMERIC(14,2) NOT NULL,

  FOREIGN KEY (iid) REFERENCES ingredients(iid),
  UNIQUE (pdate, iid)
);

CREATE OR REPLACE FUNCTION recalculate_dish_nrv(p_did UUID)
RETURNS VOID AS $$
DECLARE
  v_energy NUMERIC := 0;
  v_protein NUMERIC := 0;
  v_fat NUMERIC := 0;
  v_carb NUMERIC := 0;
  v_sodium NUMERIC := 0;
BEGIN
  SELECT
    COALESCE(SUM(i.energy * di.weight / 100), 0),
    COALESCE(SUM(i.protein * di.weight / 100), 0),
    COALESCE(SUM(i.fat * di.weight / 100), 0),
    COALESCE(SUM(i.carbohydrates * di.weight / 100), 0),
    COALESCE(SUM(i.sodium * di.weight / 100), 0)
  INTO
    v_energy, v_protein, v_fat, v_carb, v_sodium
  FROM dishes_ingredients di
  JOIN ingredients i ON di.iid = i.iid
  WHERE di.did = p_did;

  INSERT INTO dish_nrv (did, energy_pct, protein_pct, fat_pct, carbohydrates_pct, sodium_pct)
  VALUES (
    p_did,
    v_energy / (SELECT nrv_value FROM nrv_standard WHERE nutrient='energy') * 100,
    v_protein / (SELECT nrv_value FROM nrv_standard WHERE nutrient='protein') * 100,
    v_fat / (SELECT nrv_value FROM nrv_standard WHERE nutrient='fat') * 100,
    v_carb / (SELECT nrv_value FROM nrv_standard WHERE nutrient='carbohydrates') * 100,
    v_sodium / (SELECT nrv_value FROM nrv_standard WHERE nutrient='sodium') * 100
  )
  ON CONFLICT (did)
  DO UPDATE SET
    energy_pct = EXCLUDED.energy_pct,
    protein_pct = EXCLUDED.protein_pct,
    fat_pct = EXCLUDED.fat_pct,
    carbohydrates_pct = EXCLUDED.carbohydrates_pct,
    sodium_pct = EXCLUDED.sodium_pct;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_recalc_nrv()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM recalculate_dish_nrv(
    COALESCE(NEW.did, OLD.did)
  );
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalc_nrv
AFTER INSERT OR UPDATE OR DELETE
ON dishes_ingredients
FOR EACH ROW
EXECUTE FUNCTION trigger_recalc_nrv();
