-- ============================================================
-- Supply Chain Track & Trace — Trial Exercise Seed Data
-- Oracle 12c+ / XE 21c compatible
-- Run as schema owner
-- 30 customer orders, 30 WH orders, 30 transport orders, ~300 events
-- All users: Password123!
-- ============================================================

-- ── CLEANUP (FK-safe order) ──────────────────────────────────
DELETE FROM ORDER_EVENT;
DELETE FROM TRANSPORT_ORDER;
DELETE FROM WAREHOUSE_ORDER;
DELETE FROM CUSTOMER_ORDER_LINE;
DELETE FROM CUSTOMER_ORDER;
DELETE FROM APP_USER;
DELETE FROM WAREHOUSE;
DELETE FROM CUSTOMER;
COMMIT;

-- ── SEQUENCES ────────────────────────────────────────────────
BEGIN
  FOR s IN (
    SELECT sequence_name FROM user_sequences
    WHERE sequence_name IN (
      'SEQ_CUSTOMER','SEQ_WAREHOUSE','SEQ_USER',
      'SEQ_CUSTOMER_ORDER','SEQ_ORDER_LINE',
      'SEQ_WAREHOUSE_ORDER','SEQ_TRANSPORT_ORDER','SEQ_EVENT')
  ) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

CREATE SEQUENCE SEQ_CUSTOMER        START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_WAREHOUSE       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_USER            START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CUSTOMER_ORDER  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_ORDER_LINE      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_WAREHOUSE_ORDER START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_TRANSPORT_ORDER START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_EVENT           START WITH 1 INCREMENT BY 1 NOCACHE;

-- ============================================================
-- 1. CUSTOMERS
-- ============================================================
INSERT INTO CUSTOMER (CUSTOMER_ID, CUSTOMER_CODE, NAME, COUNTRY_CODE, STATUS, CREATED_BY, CREATED_AT)
VALUES (SEQ_CUSTOMER.NEXTVAL, 'ACME',    'Acme Corporation', 'US', 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

INSERT INTO CUSTOMER (CUSTOMER_ID, CUSTOMER_CODE, NAME, COUNTRY_CODE, STATUS, CREATED_BY, CREATED_AT)
VALUES (SEQ_CUSTOMER.NEXTVAL, 'TECHGLB', 'TechGlobal Inc',   'DE', 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

INSERT INTO CUSTOMER (CUSTOMER_ID, CUSTOMER_CODE, NAME, COUNTRY_CODE, STATUS, CREATED_BY, CREATED_AT)
VALUES (SEQ_CUSTOMER.NEXTVAL, 'FRESHF',  'FreshFoods Ltd',   'GB', 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

COMMIT;

-- ============================================================
-- 2. WAREHOUSES
-- ============================================================
INSERT INTO WAREHOUSE (WAREHOUSE_ID, WAREHOUSE_CODE, NAME, COUNTRY_CODE, ADDRESS, CREATED_BY, CREATED_AT)
VALUES (SEQ_WAREHOUSE.NEXTVAL, 'WH-SG', 'Singapore Changi Hub',  'SG',
        '60 Airport Boulevard, Changi, Singapore 819643', 'SYSTEM', SYSTIMESTAMP);

INSERT INTO WAREHOUSE (WAREHOUSE_ID, WAREHOUSE_CODE, NAME, COUNTRY_CODE, ADDRESS, CREATED_BY, CREATED_AT)
VALUES (SEQ_WAREHOUSE.NEXTVAL, 'WH-DE', 'Frankfurt Rhine Depot',  'DE',
        'Hauptstrasse 120, 60529 Frankfurt am Main, Germany', 'SYSTEM', SYSTIMESTAMP);

COMMIT;

-- ============================================================
-- 3. USERS  (all passwords = Password123!)
-- ============================================================
DECLARE
  v_hash CONSTANT VARCHAR2(200) :=
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy';
BEGIN
  INSERT INTO APP_USER (USER_ID, USERNAME, EMAIL, ROLE, CUSTOMER_ID, PASSWORD_HASH, STATUS, CREATED_BY, CREATED_AT)
  VALUES (SEQ_USER.NEXTVAL, 'admin',          'admin@tracktrace.com',       'ADMIN',    NULL, v_hash, 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

  INSERT INTO APP_USER (USER_ID, USERNAME, EMAIL, ROLE, CUSTOMER_ID, PASSWORD_HASH, STATUS, CREATED_BY, CREATED_AT)
  VALUES (SEQ_USER.NEXTVAL, 'op.acme',        'operator@acme.com',          'OPERATOR', 1,    v_hash, 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

  INSERT INTO APP_USER (USER_ID, USERNAME, EMAIL, ROLE, CUSTOMER_ID, PASSWORD_HASH, STATUS, CREATED_BY, CREATED_AT)
  VALUES (SEQ_USER.NEXTVAL, 'op.techglb',     'operator@techglobal.de',     'OPERATOR', 2,    v_hash, 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

  INSERT INTO APP_USER (USER_ID, USERNAME, EMAIL, ROLE, CUSTOMER_ID, PASSWORD_HASH, STATUS, CREATED_BY, CREATED_AT)
  VALUES (SEQ_USER.NEXTVAL, 'viewer.acme',    'viewer@acme.com',            'VIEWER',   1,    v_hash, 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

  INSERT INTO APP_USER (USER_ID, USERNAME, EMAIL, ROLE, CUSTOMER_ID, PASSWORD_HASH, STATUS, CREATED_BY, CREATED_AT)
  VALUES (SEQ_USER.NEXTVAL, 'viewer.techglb', 'viewer@techglobal.de',       'VIEWER',   2,    v_hash, 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

  INSERT INTO APP_USER (USER_ID, USERNAME, EMAIL, ROLE, CUSTOMER_ID, PASSWORD_HASH, STATUS, CREATED_BY, CREATED_AT)
  VALUES (SEQ_USER.NEXTVAL, 'viewer.fresh',   'viewer@freshfoods.co.uk',    'VIEWER',   3,    v_hash, 'ACTIVE', 'SYSTEM', SYSTIMESTAMP);

  COMMIT;
END;
/

-- ============================================================
-- 4. MAIN DATA BLOCK
--    30 customer orders, 30 WH orders, 30 transport orders
--    ~300 events
--    Includes 3 EXCEPTION + 4 overdue orders
-- ============================================================
CREATE OR REPLACE FUNCTION rnd(lo NUMBER, hi NUMBER)
RETURN NUMBER DETERMINISTIC IS
BEGIN
  RETURN lo + TRUNC(DBMS_RANDOM.VALUE(0, hi - lo + 1));
END;
/

DECLARE
  v_co_id     NUMBER;
  v_wh_id     NUMBER;
  v_tr_id     NUMBER;
  v_co_ref    VARCHAR2(30);
  v_wh_ref    VARCHAR2(30);
  v_tr_ref    VARCHAR2(30);
  v_cust_id   NUMBER;
  v_wh_loc    NUMBER;
  v_co_status VARCHAR2(30);
  v_wh_status VARCHAR2(30);
  v_tr_status VARCHAR2(30);
  v_country   VARCHAR2(5);
  v_order_date TIMESTAMP;
  v_req_del   TIMESTAMP;
  v_act_del   TIMESTAMP;

  TYPE t_str IS TABLE OF VARCHAR2(60);
  v_carriers  t_str := t_str('CargoFlex Logistics','SwiftShip GmbH','OceanBridge Ltd','PrimeMover Co','RapidFreight SG');
  v_drivers   t_str := t_str('Hans Mueller','Ahmad Karim','David Lim','Sarah Connor','Pierre Dubois');
  v_vehicles  t_str := t_str('DE-FR 8842','SG-AB 1234','GB-TF 5678','DE-MK 9901','SG-CD 3322');
  v_products  t_str := t_str(
    'Industrial Servo Motor X200','Control Board PCB-Rev3',
    'Power Supply Unit 240V','Sensor Array Module',
    'Hydraulic Pump HX-40','RFID Scanner Handheld',
    'Safety Relay DIN-Rail','Conveyor Belt Drive Unit'
  );

  PROCEDURE log_event(
    p_type VARCHAR2, p_ref VARCHAR2,
    p_code VARCHAR2, p_desc VARCHAR2,
    p_ts   TIMESTAMP, p_loc VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    INSERT INTO ORDER_EVENT (
      EVENT_ID, ORDER_TYPE, ORDER_REF, EVENT_CODE,
      EVENT_DESCRIPTION, EVENT_TIMESTAMP, LOCATION,
      CREATED_BY, CREATED_AT
    ) VALUES (
      SEQ_EVENT.NEXTVAL, p_type, p_ref, p_code,
      p_desc, p_ts, p_loc, 'SYSTEM', SYSTIMESTAMP
    );
  END;

BEGIN
  FOR i IN 1..30 LOOP

    -- ── Customer assignment (10 each) ────────────────────────
    v_cust_id := CASE WHEN i <= 10 THEN 1 WHEN i <= 20 THEN 2 ELSE 3 END;
    v_country  := CASE v_cust_id WHEN 1 THEN 'US' WHEN 2 THEN 'DE' ELSE 'GB' END;
    v_wh_loc   := CASE v_cust_id WHEN 3 THEN 2 ELSE 1 END; -- customer 3 → WH-DE

    -- ── Dates (spread across past 45 days) ───────────────────
    v_order_date := SYSTIMESTAMP - rnd(1, 45);
    v_req_del    := v_order_date + rnd(5, 14);

    -- ── Status assignment ────────────────────────────────────
    --  i  1- 3: EXCEPTION (3 orders)
    --  i  4- 7: Overdue, still IN_TRANSIT (4 orders)
    --  i  8-14: DELIVERED
    --  i 15-20: SHIPPED / IN_TRANSIT
    --  i 21-25: PROCESSING / PICKING or PACKING
    --  i 26-30: RECEIVED / CREATED

    IF i BETWEEN 1 AND 3 THEN
      v_co_status := 'EXCEPTION';
      v_wh_status := 'DISPATCHED';
      v_tr_status := 'EXCEPTION';
      v_req_del   := v_order_date + rnd(2, 5);  -- short window → already overdue
      v_act_del   := NULL;

    ELSIF i BETWEEN 4 AND 7 THEN
      v_co_status := 'SHIPPED';
      v_wh_status := 'DISPATCHED';
      v_tr_status := 'IN_TRANSIT';
      v_req_del   := v_order_date + rnd(1, 3);  -- past due date
      v_act_del   := NULL;

    ELSIF i BETWEEN 8 AND 14 THEN
      v_co_status := 'DELIVERED';
      v_wh_status := 'DISPATCHED';
      v_tr_status := 'DELIVERED';
      v_act_del   := v_req_del - rnd(0, 1);

    ELSIF i BETWEEN 15 AND 20 THEN
      v_co_status := 'SHIPPED';
      v_wh_status := 'DISPATCHED';
      v_tr_status := 'IN_TRANSIT';
      v_act_del   := NULL;

    ELSIF i BETWEEN 21 AND 25 THEN
      v_co_status := 'PROCESSING';
      v_wh_status := CASE MOD(i,2) WHEN 0 THEN 'PICKING' ELSE 'PACKING' END;
      v_tr_status := 'PLANNED';
      v_act_del   := NULL;

    ELSE
      v_co_status := 'RECEIVED';
      v_wh_status := 'CREATED';
      v_tr_status := 'PLANNED';
      v_act_del   := NULL;
    END IF;

    -- ── Customer Order ────────────────────────────────────────
    v_co_id  := SEQ_CUSTOMER_ORDER.NEXTVAL;
    v_co_ref := 'CO-2026-' || LPAD(v_co_id, 6, '0');

    INSERT INTO CUSTOMER_ORDER (
      ORDER_ID, ORDER_REF, CUSTOMER_ID, COUNTRY_CODE,
      ORDER_DATE, REQUESTED_DELIVERY_DATE, ACTUAL_DELIVERY_DATE,
      STATUS, TOTAL_ITEMS, TOTAL_WEIGHT_KG,
      CREATED_BY, CREATED_AT, UPDATED_BY, UPDATED_AT
    ) VALUES (
      v_co_id, v_co_ref, v_cust_id, v_country,
      v_order_date, v_req_del, v_act_del,
      v_co_status, rnd(10,150), rnd(100,3000),
      'SYSTEM', SYSTIMESTAMP, 'SYSTEM', SYSTIMESTAMP
    );

    -- ── 2-3 Line Items ────────────────────────────────────────
    FOR li IN 1..rnd(2, 3) LOOP
      INSERT INTO CUSTOMER_ORDER_LINE (
        LINE_ID, ORDER_ID, SKU, PRODUCT_NAME, QUANTITY, UNIT_PRICE,
        CREATED_BY, CREATED_AT
      ) VALUES (
        SEQ_ORDER_LINE.NEXTVAL, v_co_id,
        'SKU-' || LPAD(rnd(1000, 9999), 4, '0'),
        v_products(MOD(li + i, 8) + 1),
        rnd(5, 60),
        ROUND(DBMS_RANDOM.VALUE(20, 300), 2),
        'SYSTEM', SYSTIMESTAMP
      );
    END LOOP;

    -- ── Warehouse Order ───────────────────────────────────────
    v_wh_id  := SEQ_WAREHOUSE_ORDER.NEXTVAL;
    v_wh_ref := 'WH-2026-' || LPAD(v_wh_id, 6, '0');

    INSERT INTO WAREHOUSE_ORDER (
      WH_ORDER_ID, WH_ORDER_REF, ORDER_ID, WAREHOUSE_ID,
      STATUS, ASSIGNED_TO,
      CREATED_BY, CREATED_AT, UPDATED_BY, UPDATED_AT
    ) VALUES (
      v_wh_id, v_wh_ref, v_co_id, v_wh_loc,
      v_wh_status,
      CASE MOD(i, 3) WHEN 0 THEN 'op.acme' WHEN 1 THEN 'op.techglb' ELSE NULL END,
      'SYSTEM', SYSTIMESTAMP, 'SYSTEM', SYSTIMESTAMP
    );

    -- ── Transport Order ───────────────────────────────────────
    v_tr_id  := SEQ_TRANSPORT_ORDER.NEXTVAL;
    v_tr_ref := 'TR-2026-' || LPAD(v_tr_id, 6, '0');

    INSERT INTO TRANSPORT_ORDER (
      TRANSPORT_ID, TRANSPORT_REF, ORDER_ID, WH_ORDER_ID,
      CARRIER_NAME, VEHICLE_REG, DRIVER_NAME, STATUS,
      ORIGIN_ADDRESS, DEST_ADDRESS, EST_DELIVERY_DATE,
      CREATED_BY, CREATED_AT, UPDATED_BY, UPDATED_AT
    ) VALUES (
      v_tr_id, v_tr_ref, v_co_id, v_wh_id,
      v_carriers(rnd(1, 5)), v_vehicles(rnd(1, 5)), v_drivers(rnd(1, 5)),
      v_tr_status,
      CASE v_wh_loc WHEN 1 THEN '60 Airport Blvd, Changi, Singapore'
                            ELSE 'Hauptstrasse 120, Frankfurt, Germany' END,
      CASE v_country WHEN 'US' THEN '3450 Industrial Ave, Los Angeles, CA'
                     WHEN 'DE' THEN 'Industriepark 8, 10115 Berlin, Germany'
                               ELSE '12 Cargo Road, Heathrow, London, UK' END,
      v_req_del + rnd(0, 2),
      'SYSTEM', SYSTIMESTAMP, 'SYSTEM', SYSTIMESTAMP
    );

    -- ── Events ───────────────────────────────────────────────
    -- Always: order received + WH created
    log_event('CUSTOMER_ORDER', v_co_ref, 'ORDER_RECEIVED',
      'Order received from ' || CASE v_cust_id WHEN 1 THEN 'Acme Corporation'
        WHEN 2 THEN 'TechGlobal Inc' ELSE 'FreshFoods Ltd' END,
      v_order_date);

    log_event('WAREHOUSE_ORDER', v_wh_ref, 'WH_ORDER_CREATED',
      'Warehouse order created and queued',
      v_order_date + INTERVAL '1' HOUR,
      CASE v_wh_loc WHEN 1 THEN 'Singapore Changi Hub' ELSE 'Frankfurt Rhine Depot' END);

    -- Processing onwards
    IF v_wh_status IN ('PICKING','PACKING','DISPATCHED') THEN
      log_event('CUSTOMER_ORDER', v_co_ref, 'PROCESSING',
        'Order entered fulfilment processing', v_order_date + INTERVAL '2' HOUR);
      log_event('WAREHOUSE_ORDER', v_wh_ref, 'PICK_STARTED',
        'Pick list generated, operator assigned', v_order_date + INTERVAL '2' HOUR,
        CASE v_wh_loc WHEN 1 THEN 'Singapore Changi Hub' ELSE 'Frankfurt Rhine Depot' END);
    END IF;

    IF v_wh_status IN ('PACKING','DISPATCHED') THEN
      log_event('WAREHOUSE_ORDER', v_wh_ref, 'PICK_COMPLETE',
        'All items picked and verified', v_order_date + INTERVAL '4' HOUR,
        CASE v_wh_loc WHEN 1 THEN 'Singapore Changi Hub' ELSE 'Frankfurt Rhine Depot' END);
      log_event('WAREHOUSE_ORDER', v_wh_ref, 'PACK_STARTED',
        'Packing commenced', v_order_date + INTERVAL '5' HOUR,
        CASE v_wh_loc WHEN 1 THEN 'Singapore Changi Hub' ELSE 'Frankfurt Rhine Depot' END);
    END IF;

    IF v_wh_status = 'DISPATCHED' THEN
      log_event('WAREHOUSE_ORDER', v_wh_ref, 'DISPATCHED',
        'Shipment handed to carrier for collection', v_order_date + INTERVAL '8' HOUR,
        CASE v_wh_loc WHEN 1 THEN 'Singapore Changi Hub' ELSE 'Frankfurt Rhine Depot' END);
    END IF;

    -- Transport events
    log_event('TRANSPORT_ORDER', v_tr_ref, 'TR_PLANNED',
      'Transport order planned and assigned to carrier', v_order_date + INTERVAL '3' HOUR);

    IF v_tr_status IN ('IN_TRANSIT','DELIVERED','EXCEPTION') THEN
      log_event('TRANSPORT_ORDER', v_tr_ref, 'PICKED_UP',
        'Goods collected from warehouse by carrier',
        v_order_date + INTERVAL '8' HOUR,
        CASE v_wh_loc WHEN 1 THEN 'Singapore Changi Hub' ELSE 'Frankfurt Rhine Depot' END);
      log_event('CUSTOMER_ORDER', v_co_ref, 'SHIPPED',
        'Order dispatched to carrier', v_order_date + INTERVAL '8' HOUR);
      log_event('TRANSPORT_ORDER', v_tr_ref, 'IN_TRANSIT',
        'Shipment in transit to destination', v_order_date + INTERVAL '20' HOUR, 'In transit');
    END IF;

    IF v_tr_status = 'EXCEPTION' THEN
      log_event('TRANSPORT_ORDER', v_tr_ref, 'EXCEPTION',
        'Delivery exception: address inaccessible, returning to depot',
        v_order_date + INTERVAL '36' HOUR, 'Destination region');
      log_event('CUSTOMER_ORDER', v_co_ref, 'EXCEPTION',
        'Delivery exception raised — customer notified',
        v_order_date + INTERVAL '36' HOUR);
    END IF;

    IF v_tr_status = 'DELIVERED' THEN
      log_event('TRANSPORT_ORDER', v_tr_ref, 'DELIVERED',
        'Successfully delivered to customer',
        v_act_del,
        CASE v_country WHEN 'US' THEN 'Los Angeles, CA'
                       WHEN 'DE' THEN 'Berlin, Germany'
                                  ELSE 'London, UK' END);
      log_event('CUSTOMER_ORDER', v_co_ref, 'DELIVERED',
        'Order delivered and confirmed by customer', v_act_del);
    END IF;

    COMMIT;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Seed complete.');
  DBMS_OUTPUT.PUT_LINE('Customer orders : 30');
  DBMS_OUTPUT.PUT_LINE('Warehouse orders: 30');
  DBMS_OUTPUT.PUT_LINE('Transport orders: 30');
  DBMS_OUTPUT.PUT_LINE('Exception orders: 3  (CO-2026-000001 to 000003)');
  DBMS_OUTPUT.PUT_LINE('Overdue orders  : 4  (CO-2026-000004 to 000007)');
  DBMS_OUTPUT.PUT_LINE('Events          : ~280 (varies by status)');
END;
/

-- ============================================================
-- 5. V_ORDER_SEARCH — unified search view
-- ============================================================
CREATE OR REPLACE VIEW V_ORDER_SEARCH AS
  SELECT co.ORDER_ID, co.ORDER_REF, 'CUSTOMER' AS ORDER_TYPE,
         c.NAME AS CUSTOMER_NAME, co.STATUS, co.COUNTRY_CODE,
         co.UPDATED_AT, co.REQUESTED_DELIVERY_DATE AS ETA
  FROM   CUSTOMER_ORDER co
  JOIN   CUSTOMER c ON c.CUSTOMER_ID = co.CUSTOMER_ID
UNION ALL
  SELECT wo.WH_ORDER_ID, wo.WH_ORDER_REF, 'WAREHOUSE' AS ORDER_TYPE,
         c.NAME AS CUSTOMER_NAME, wo.STATUS, co.COUNTRY_CODE,
         wo.UPDATED_AT, NULL AS ETA
  FROM   WAREHOUSE_ORDER wo
  JOIN   CUSTOMER_ORDER  co ON co.ORDER_ID   = wo.ORDER_ID
  JOIN   CUSTOMER        c  ON c.CUSTOMER_ID = co.CUSTOMER_ID
UNION ALL
  SELECT tr.TRANSPORT_ID, tr.TRANSPORT_REF, 'TRANSPORT' AS ORDER_TYPE,
         c.NAME AS CUSTOMER_NAME, tr.STATUS, co.COUNTRY_CODE,
         tr.UPDATED_AT, tr.EST_DELIVERY_DATE AS ETA
  FROM   TRANSPORT_ORDER tr
  JOIN   CUSTOMER_ORDER  co ON co.ORDER_ID   = tr.ORDER_ID
  JOIN   CUSTOMER        c  ON c.CUSTOMER_ID = co.CUSTOMER_ID;

-- ============================================================
-- 6. INDEXES
-- ============================================================
CREATE INDEX IDX_CO_ORDER_REF  ON CUSTOMER_ORDER  (ORDER_REF);
CREATE INDEX IDX_CO_STATUS     ON CUSTOMER_ORDER  (STATUS);
CREATE INDEX IDX_CO_CUSTOMER   ON CUSTOMER_ORDER  (CUSTOMER_ID);
CREATE INDEX IDX_WO_ORDER_REF  ON WAREHOUSE_ORDER (WH_ORDER_REF);
CREATE INDEX IDX_WO_STATUS     ON WAREHOUSE_ORDER (STATUS);
CREATE INDEX IDX_TR_ORDER_REF  ON TRANSPORT_ORDER (TRANSPORT_REF);
CREATE INDEX IDX_TR_STATUS     ON TRANSPORT_ORDER (STATUS);
CREATE INDEX IDX_EVENT_REF_TS  ON ORDER_EVENT     (ORDER_REF, EVENT_TIMESTAMP DESC);

-- ============================================================
-- 7. VERIFICATION QUERIES
-- ============================================================
SELECT 'CUSTOMER'        AS TBL, COUNT(*) AS CNT FROM CUSTOMER        UNION ALL
SELECT 'WAREHOUSE',      COUNT(*) FROM WAREHOUSE                       UNION ALL
SELECT 'APP_USER',       COUNT(*) FROM APP_USER                        UNION ALL
SELECT 'CUSTOMER_ORDER', COUNT(*) FROM CUSTOMER_ORDER                  UNION ALL
SELECT 'ORDER_LINE',     COUNT(*) FROM CUSTOMER_ORDER_LINE             UNION ALL
SELECT 'WAREHOUSE_ORDER',COUNT(*) FROM WAREHOUSE_ORDER                 UNION ALL
SELECT 'TRANSPORT_ORDER',COUNT(*) FROM TRANSPORT_ORDER                 UNION ALL
SELECT 'ORDER_EVENT',    COUNT(*) FROM ORDER_EVENT;

SELECT STATUS, COUNT(*) AS CNT
FROM   CUSTOMER_ORDER
GROUP  BY STATUS
ORDER  BY STATUS;

-- ============================================================
-- QUICK REFERENCE: Test Users
-- ============================================================
-- Username          Password       Role      Customer
-- ─────────────────────────────────────────────────────────
-- admin             Password123!   ADMIN     (all data)
-- op.acme           Password123!   OPERATOR  Acme Corporation
-- op.techglb        Password123!   OPERATOR  TechGlobal Inc
-- viewer.acme       Password123!   VIEWER    Acme Corporation
-- viewer.techglb    Password123!   VIEWER    TechGlobal Inc
-- viewer.fresh      Password123!   VIEWER    FreshFoods Ltd
-- ============================================================
-- END OF TRIAL SEED SCRIPT
-- ============================================================
