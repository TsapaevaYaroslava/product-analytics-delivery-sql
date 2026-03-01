import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

np.random.seed(42)
random.seed(42)

# ----------------------
# ПАРАМЕТРЫ
# ----------------------
NUM_USERS = 12000
NUM_RESTAURANTS = 120
NUM_ORDERS = 60000
START_DATE = datetime(2024, 1, 1)
END_DATE = datetime(2024, 6, 30)

cities = ["Moscow", "Saint Petersburg", "Kazan"]
categories = ["Italian", "Asian", "Burgers", "Healthy", "Georgian"]

# ----------------------
# USERS
# ----------------------
users = []
for user_id in range(1, NUM_USERS + 1):
    signup_offset = np.random.randint(0, (END_DATE - START_DATE).days)
    signup_ts = START_DATE + timedelta(days=int(signup_offset))
    city = random.choice(cities)
    users.append([user_id, signup_ts, city])

users_df = pd.DataFrame(users, columns=["user_id", "signup_ts", "city"])

# ----------------------
# RESTAURANTS
# ----------------------
restaurants = []
for rest_id in range(1, NUM_RESTAURANTS + 1):
    city = random.choice(cities)
    category = random.choice(categories)
    restaurants.append([rest_id, city, category])

restaurants_df = pd.DataFrame(restaurants, columns=["restaurant_id", "city", "category"])

# ----------------------
# ORDERS
# ----------------------
orders = []
order_id = 1

date_range_days = (END_DATE - START_DATE).days

for _ in range(NUM_ORDERS):
    user = users_df.sample(1).iloc[0]
    user_id = user["user_id"]
    city = user["city"]

    # Заказ после регистрации
    order_day_offset = np.random.randint(0, date_range_days)
    created_ts = START_DATE + timedelta(days=int(order_day_offset),
                                        minutes=np.random.randint(0, 1440))

    # Немного больше заказов в выходные
    if created_ts.weekday() in [4, 5]:  # пятница, суббота
        if random.random() < 0.2:
            created_ts += timedelta(minutes=30)

    # Выбор ресторана в том же городе
    rest = restaurants_df[restaurants_df["city"] == city].sample(1).iloc[0]
    restaurant_id = rest["restaurant_id"]

    # Статус
    cancel_prob = 0.1
    if random.random() < cancel_prob:
        status = "canceled"
        cancel_reason = random.choice(["client", "restaurant", "courier"])
        assigned_ts = created_ts + timedelta(minutes=np.random.randint(3, 8))
        picked_up_ts = None
        delivered_ts = None
        canceled_ts = assigned_ts + timedelta(minutes=np.random.randint(1, 5))
    else:
        status = "delivered"
        cancel_reason = None
        assigned_ts = created_ts + timedelta(minutes=np.random.randint(3, 12))
        picked_up_ts = assigned_ts + timedelta(minutes=np.random.randint(10, 20))
        delivery_time = np.random.randint(25, 70)
        delivered_ts = created_ts + timedelta(minutes=delivery_time)
        canceled_ts = None

    total_amount = round(np.random.normal(1300, 400), 2)
    total_amount = max(300, total_amount)

    promo_discount = 0
    if random.random() < 0.25:
        promo_discount = round(total_amount * random.uniform(0.05, 0.25), 2)

    delivery_fee = round(random.uniform(99, 199), 2)

    orders.append([
        order_id, user_id, restaurant_id,
        created_ts, assigned_ts, picked_up_ts,
        delivered_ts, canceled_ts,
        status, cancel_reason,
        total_amount, delivery_fee, promo_discount
    ])

    order_id += 1

orders_df = pd.DataFrame(orders, columns=[
    "order_id", "user_id", "restaurant_id",
    "created_ts", "assigned_ts", "picked_up_ts",
    "delivered_ts", "canceled_ts",
    "status", "cancel_reason",
    "total_amount", "delivery_fee", "promo_discount"
])

# ----------------------
# SAVE CSV
# ----------------------
users_df.to_csv("users.csv", index=False)
restaurants_df.to_csv("restaurants.csv", index=False)
orders_df.to_csv("orders.csv", index=False)

print("Данные успешно сгенерированы.")
