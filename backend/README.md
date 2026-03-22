
```bash
sudo yum install mariadb105 -y
```

OR (recommended newer package):

```bash
sudo dnf install mariadb -y
```


```bash
mysql -h book-rds.c4row02me3au.us-east-1.rds.amazonaws.com -u admin -p < test.sql
```

---

### 1. RDS must allow access

Make sure:

* Security Group allows **port 3306**
* Source = your EC2 instance SG or IP

---

### 2. RDS must be publicly accessible (if needed)

If EC2 is not in same VPC:

* Enable **Public access = YES**

---

### 3. Credentials correct

* Username: `admin`
* Password: (you’ll be prompted)

---

## 🧠 Pro tip (very useful)

To test connection first:

```bash
mysql -h book-rds.c4row02me3au.us-east-1.rds.amazonaws.com -u admin -p
```

# 🔄 Switch Database

```sql
USE test;
```

👉 This selects your database (`test`)

---

# 👀 See All Databases

```sql
SHOW DATABASES;
```

---

# 📂 See Current Database

```sql
SELECT DATABASE();
```

---

# 📋 See Tables in Database

```sql
SHOW TABLES;
```

---

# 🔍 See Table Structure

```sql
DESCRIBE books;
```

OR

```sql
DESC books;
```

---

# 📊 View Data in Table

```sql
SELECT * FROM books;
```

---

# 🔎 View Limited Data (better)

```sql
SELECT * FROM books LIMIT 5;
```

---

# 🔄 Switch Table (just query it)

```sql
SELECT * FROM books;
```

👉 In SQL, you don’t “switch tables” like databases
You just query the table you want

---

# 🧠 Quick Flow (what you should do)

```sql
SHOW DATABASES;
USE test;
SHOW TABLES;
SELECT * FROM books;
```

---

