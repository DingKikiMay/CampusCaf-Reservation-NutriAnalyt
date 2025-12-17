-- 1. USERS
CREATE TABLE users (
    uid UUID PRIMARY KEY,
    uname VARCHAR(50) NOT NULL
);

-- 2. INGREDIENTS
CREATE TABLE ingredients (
    iid UUID PRIMARY KEY,
    iname VARCHAR(50) NOT NULL,
    energy NUMERIC(10,2),
    protein NUMERIC(10,2),
    fat NUMERIC(10,2),
    carbohydrates NUMERIC(10,2),
    sodium NUMERIC(10,2)
);

-- 3. DISHES
CREATE TABLE dishes (
    did UUID PRIMARY KEY,
    dname VARCHAR(50) NOT NULL,
    price NUMERIC(10,2)
);

-- 4. DISHES_INGREDIENTS (多对多)
CREATE TABLE dishes_ingredients (
    did UUID NOT NULL,
    iid UUID NOT NULL,
    weight NUMERIC(10,2) NOT NULL,

    PRIMARY KEY (did, iid),
    FOREIGN KEY (did) REFERENCES dishes(did),
    FOREIGN KEY (iid) REFERENCES ingredients(iid)
);

-- 5. ORDERS
CREATE TABLE orders (
    oid UUID PRIMARY KEY,
    uid UUID NOT NULL,
    odate DATE NOT NULL,
    otime TIME NOT NULL,
    status VARCHAR(10) NOT NULL CHECK 
        (status IN ('pending','confirmed','cancelled','served')),
    orders_version INT DEFAULT 0,
    pickup_qr UUID,

    FOREIGN KEY (uid) REFERENCES users(uid)
);

-- 6. ORDERS_DISHES（订单项）
CREATE TABLE orders_dishes (
    o_dno UUID PRIMARY KEY,
    oid UUID NOT NULL,
    did UUID NOT NULL,
    qty INT NOT NULL CHECK (qty > 0),
    note TEXT,

    FOREIGN KEY (oid) REFERENCES orders(oid),
    FOREIGN KEY (did) REFERENCES dishes(did)
);

-- 7. PREPARATIONS（备菜表）
CREATE TABLE preparations (
    pid UUID PRIMARY KEY,
    pdate DATE NOT NULL,
    iid UUID,
    required_g NUMERIC(14,2) NOT NULL,

    FOREIGN KEY (iid) REFERENCES ingredients(iid)
);

-- 8. NRV
CREATE TABLE nrv (
    nutrient VARCHAR(30) PRIMARY KEY,
    nrv_value NUMERIC(12,2)
);