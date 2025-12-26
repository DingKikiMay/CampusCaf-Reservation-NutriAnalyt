-- 插入用户数据
INSERT INTO users (uname) VALUES
('张三'),
('李四'),
('王五'),
('赵六'),
('钱七');

-- 插入营养成分参考值标准（需要先创建这个表）
CREATE TABLE nrv_standard (
  nutrient VARCHAR(20) PRIMARY KEY,
  nrv_value NUMERIC(10,2) NOT NULL
);

INSERT INTO nrv_standard (nutrient, nrv_value) VALUES
('energy', 2000),       -- 2000 kcal
('protein', 60),        -- 60 g
('fat', 60),            -- 60 g
('carbohydrates', 300), -- 300 g
('sodium', 2000);       -- 2000 mg

-- 插入食材数据
INSERT INTO ingredients (iname, energy, protein, fat, carbohydrates, sodium) VALUES
-- 主食类
('大米', 346.0, 7.4, 0.8, 77.2, 2.0),
('面粉', 364.0, 10.3, 1.1, 76.1, 3.0),
('面条', 138.0, 4.8, 0.7, 28.5, 150.0),
-- 蔬菜类
('番茄', 18.0, 0.9, 0.2, 3.9, 5.0),
('鸡蛋', 147.0, 12.9, 9.9, 1.5, 142.0),
('牛肉', 250.0, 26.0, 15.0, 0.0, 65.0),
('鸡肉', 167.0, 24.0, 6.6, 0.0, 74.0),
('猪肉', 242.0, 17.0, 20.0, 0.0, 57.0),
('土豆', 77.0, 2.0, 0.1, 17.0, 6.0),
('胡萝卜', 41.0, 1.0, 0.2, 9.6, 69.0),
('青椒', 20.0, 1.0, 0.2, 4.6, 3.0),
('洋葱', 40.0, 1.1, 0.1, 9.3, 4.0),
-- 调料类
('食用油', 884.0, 0.0, 100.0, 0.0, 0.0),
('盐', 0.0, 0.0, 0.0, 0.0, 38758.0),
('酱油', 63.0, 6.8, 0.1, 9.9, 5750.0);

-- 插入菜品数据
INSERT INTO dishes (dname, price) VALUES
('番茄炒蛋', 18.00),
('青椒肉丝', 25.00),
('土豆烧牛肉', 38.00),
('宫保鸡丁', 28.00),
('红烧肉', 32.00),
('鱼香肉丝', 26.00);

-- 插入菜品食材关系
-- 番茄炒蛋（假设一份300g：番茄200g + 鸡蛋2个约100g）
INSERT INTO dishes_ingredients (did, iid, weight) VALUES
((SELECT did FROM dishes WHERE dname='番茄炒蛋'), (SELECT iid FROM ingredients WHERE iname='番茄'), 200),
((SELECT did FROM dishes WHERE dname='番茄炒蛋'), (SELECT iid FROM ingredients WHERE iname='鸡蛋'), 100),
((SELECT did FROM dishes WHERE dname='番茄炒蛋'), (SELECT iid FROM ingredients WHERE iname='食用油'), 10),
((SELECT did FROM dishes WHERE dname='番茄炒蛋'), (SELECT iid FROM ingredients WHERE iname='盐'), 2);

-- 青椒肉丝（假设一份350g：青椒150g + 猪肉200g）
INSERT INTO dishes_ingredients (did, iid, weight) VALUES
((SELECT did FROM dishes WHERE dname='青椒肉丝'), (SELECT iid FROM ingredients WHERE iname='青椒'), 150),
((SELECT did FROM dishes WHERE dname='青椒肉丝'), (SELECT iid FROM ingredients WHERE iname='猪肉'), 200),
((SELECT did FROM dishes WHERE dname='青椒肉丝'), (SELECT iid FROM ingredients WHERE iname='食用油'), 15),
((SELECT did FROM dishes WHERE dname='青椒肉丝'), (SELECT iid FROM ingredients WHERE iname='盐'), 3),
((SELECT did FROM dishes WHERE dname='青椒肉丝'), (SELECT iid FROM ingredients WHERE iname='酱油'), 10);

-- 土豆烧牛肉（假设一份400g：土豆200g + 牛肉200g）
INSERT INTO dishes_ingredients (did, iid, weight) VALUES
((SELECT did FROM dishes WHERE dname='土豆烧牛肉'), (SELECT iid FROM ingredients WHERE iname='土豆'), 200),
((SELECT did FROM dishes WHERE dname='土豆烧牛肉'), (SELECT iid FROM ingredients WHERE iname='牛肉'), 200),
((SELECT did FROM dishes WHERE dname='土豆烧牛肉'), (SELECT iid FROM ingredients WHERE iname='食用油'), 20),
((SELECT did FROM dishes WHERE dname='土豆烧牛肉'), (SELECT iid FROM ingredients WHERE iname='盐'), 4),
((SELECT did FROM dishes WHERE dname='土豆烧牛肉'), (SELECT iid FROM ingredients WHERE iname='酱油'), 15);

-- 宫保鸡丁（假设一份350g：鸡肉250g + 胡萝卜100g）
INSERT INTO dishes_ingredients (did, iid, weight) VALUES
((SELECT did FROM dishes WHERE dname='宫保鸡丁'), (SELECT iid FROM ingredients WHERE iname='鸡肉'), 250),
((SELECT did FROM dishes WHERE dname='宫保鸡丁'), (SELECT iid FROM ingredients WHERE iname='胡萝卜'), 100),
((SELECT did FROM dishes WHERE dname='宫保鸡丁'), (SELECT iid FROM ingredients WHERE iname='食用油'), 15),
((SELECT did FROM dishes WHERE dname='宫保鸡丁'), (SELECT iid FROM ingredients WHERE iname='盐'), 3);

-- 手动触发NRV计算（因为触发器已经存在）
SELECT recalculate_dish_nrv(did) FROM dishes;

-- 插入订单数据
INSERT INTO orders (odate, meal_slot, uid, status) VALUES
(CURRENT_DATE, 'lunch', (SELECT uid FROM users WHERE uname='张三'), 'confirmed'),
(CURRENT_DATE, 'lunch', (SELECT uid FROM users WHERE uname='李四'), 'pending'),
(CURRENT_DATE, 'dinner', (SELECT uid FROM users WHERE uname='王五'), 'served'),
(CURRENT_DATE + INTERVAL '1 day', 'lunch', (SELECT uid FROM users WHERE uname='赵六'), 'confirmed'),
(CURRENT_DATE + INTERVAL '1 day', 'dinner', (SELECT uid FROM users WHERE uname='钱七'), 'cancelled');

-- 插入订单菜品明细
INSERT INTO orders_dishes (oid, did, qty, unit_price) VALUES
-- 张三的订单：番茄炒蛋1份 + 宫保鸡丁1份
((SELECT oid FROM orders WHERE uid=(SELECT uid FROM users WHERE uname='张三') LIMIT 1),
 (SELECT did FROM dishes WHERE dname='番茄炒蛋'), 1, 18.00),
((SELECT oid FROM orders WHERE uid=(SELECT uid FROM users WHERE uname='张三') LIMIT 1),
 (SELECT did FROM dishes WHERE dname='宫保鸡丁'), 1, 28.00),

-- 李四的订单：青椒肉丝2份
((SELECT oid FROM orders WHERE uid=(SELECT uid FROM users WHERE uname='李四') LIMIT 1),
 (SELECT did FROM dishes WHERE dname='青椒肉丝'), 2, 25.00),

-- 王五的订单：土豆烧牛肉1份
((SELECT oid FROM orders WHERE uid=(SELECT uid FROM users WHERE uname='王五') LIMIT 1),
 (SELECT did FROM dishes WHERE dname='土豆烧牛肉'), 1, 38.00),

-- 赵六的订单：红烧肉1份 + 鱼香肉丝1份
((SELECT oid FROM orders WHERE uid=(SELECT uid FROM users WHERE uname='赵六') LIMIT 1),
 (SELECT did FROM dishes WHERE dname='红烧肉'), 1, 32.00),
((SELECT oid FROM orders WHERE uid=(SELECT uid FROM users WHERE uname='赵六') LIMIT 1),
 (SELECT did FROM dishes WHERE dname='鱼香肉丝'), 1, 26.00);

-- 插入备餐数据（未来3天的备餐计划）
INSERT INTO preparations (pdate, iid, required_g) VALUES
-- 明天的备餐
(CURRENT_DATE + INTERVAL '1 day', (SELECT iid FROM ingredients WHERE iname='大米'), 5000),
(CURRENT_DATE + INTERVAL '1 day', (SELECT iid FROM ingredients WHERE iname='猪肉'), 3000),
(CURRENT_DATE + INTERVAL '1 day', (SELECT iid FROM ingredients WHERE iname='鸡肉'), 2000),
(CURRENT_DATE + INTERVAL '1 day', (SELECT iid FROM ingredients WHERE iname='番茄'), 2000),
(CURRENT_DATE + INTERVAL '1 day', (SELECT iid FROM ingredients WHERE iname='鸡蛋'), 2000),

-- 后天的备餐
(CURRENT_DATE + INTERVAL '2 days', (SELECT iid FROM ingredients WHERE iname='大米'), 4000),
(CURRENT_DATE + INTERVAL '2 days', (SELECT iid FROM ingredients WHERE iname='牛肉'), 2500),
(CURRENT_DATE + INTERVAL '2 days', (SELECT iid FROM ingredients WHERE iname='土豆'), 3000),
(CURRENT_DATE + INTERVAL '2 days', (SELECT iid FROM ingredients WHERE iname='青椒'), 1500);