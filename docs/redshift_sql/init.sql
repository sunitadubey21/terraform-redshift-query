CREATE TABLE users
(
    identifier INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    "name"     VARCHAR NOT NULL,
    email      VARCHAR NULL
);

INSERT INTO users (name, email)
VALUES
    ('John', 'john@doe.com'),
    ('Emily', 'emily@doe.com'),
    ('Joe', null);

CREATE TABLE items
(
    identifier INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    "name"     VARCHAR NOT NULL,
    validity   TIMESTAMP WITHOUT TIME ZONE
);

INSERT INTO items (name, validity)
VALUES
    ('Dorito', to_timestamp('2030-12-31', 'YYYY-MM-DD')),
    ('Milk', to_timestamp('2030-12-31', 'YYYY-MM-DD'));

CREATE TABLE credit_cards
(
    number       VARCHAR(16) NOT NULL,
    name_on_card VARCHAR NOT NULL,
    cvv          VARCHAR(3) NOT NULL,
    created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT current_date
);

INSERT INTO credit_cards (number, name_on_card, cvv)
VALUES
    ('1234567812345678', 'John Doe', '909'),
    ('8765432187654321', 'Emily Doe', '090');