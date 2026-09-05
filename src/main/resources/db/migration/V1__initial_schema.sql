CREATE TABLE fruit_and_vege (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255),
    barcode VARCHAR(255),
    price DOUBLE,
    in_stock_quantity INT,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE processed_food (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255),
    barcode VARCHAR(255),
    price DOUBLE,
    in_stock_quantity INT,
    food_type VARCHAR(255),
    mfg_date DATE,
    exp_date DATE,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE stationary (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255),
    barcode VARCHAR(255),
    price DOUBLE,
    in_stock_quantity INT,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE member (
    id BIGINT NOT NULL AUTO_INCREMENT,
    member_number VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    phone_number VARCHAR(255),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE ordered_item (
    id BIGINT NOT NULL AUTO_INCREMENT,
    dtype VARCHAR(31) NOT NULL,
    name VARCHAR(255),
    barcode VARCHAR(255),
    price DOUBLE,
    quantity INT,
    food_type VARCHAR(255),
    mfg_date DATE,
    exp_date DATE,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE purchase_order (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATE,
    quantity INT,
    member_number VARCHAR(255),
    receipt_number VARCHAR(255),
    total_price FLOAT,
    discount_amount FLOAT,
    price_after_discount FLOAT,
    payment_type VARCHAR(255),
    member_id BIGINT,
    PRIMARY KEY (id),
    CONSTRAINT fk_purchase_order_member
        FOREIGN KEY (member_id) REFERENCES member (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE purchase_order_ordered_item (
    purchase_order_id BIGINT NOT NULL,
    items_id BIGINT NOT NULL,
    PRIMARY KEY (purchase_order_id, items_id),
    CONSTRAINT uk_purchase_order_ordered_item_item UNIQUE (items_id),
    CONSTRAINT fk_purchase_order_ordered_item_order
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_order (id),
    CONSTRAINT fk_purchase_order_ordered_item_item
        FOREIGN KEY (items_id) REFERENCES ordered_item (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;