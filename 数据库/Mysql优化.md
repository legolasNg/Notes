## mysql语句优化

mysql的优化，三分是配置的优化，七分是sql语句的优化。

- 不是所有sql语句都能通过sql优化，有时候可以调整业务逻辑
- 大部分时候通过空间换时间，冗余数据来提高性能(大化小，分而治之)
- 多利用explain来分析sql语句
- 索引利大于弊，多使用、有效利用索引

### 1.简化sql，将部分逻辑放到代码层

### 2.数据量过大的表，部分数据单独建表

### 3.添加冗余字段，减少大表联合查询

### 4.索引优化 -- 最左前缀原则

### 5.关注数据库状态 -- show processlist

##

## sql语法拓展 -- WITH (T-SQL、Oracle支持)

**WITH AS** 短语，也叫做子查询部分(subquery factoring)，定义一个sql片段，该sql片段会被整个sql语句用到。

优点：

- 让sql语句的可读性更高
- 避免重复执行sql子句(如果WITH AS短语所定义的表名被调用两次以上，优化器会自动将WITH AS短语所获取的数据放入一个TEMP表；如果只是调用一次，则不会)，配合`HINT MATERIALIZE`

CTE(公用表表达式)，使用CTE，可以增加SQL语句的可维护性，同时CTE要比表变量的效率高得多。语法：

```sql
[ WITH <common_table_expression> [ ,n ] ]
<common_table_expression>::=
        expression_name [ ( column_name [ ,n ] ) ]
    AS
        ( CTE_query_definition )
```

### mysql实现

通过创建临时表(TEMPORARY TABLE)或者视图(VIEW)，来达到WITH AS语句类似效果

```sql
DROP PROCEDURE `pro_test`//
CREATE DEFINER=`root`@`localhost` PROCEDURE `pro_test`(in id varchar(10))
BEGIN
    declare count int;
END
```

## HINT详解

HINT是数据库提供的一种机制，用来告诉优化器按照我们告诉它的方式来生成执行计划:

- 使用优化器的类型
- 基于代价的优化器的优化目标，是all_rows还是first_rows
- 表的访问路径，是全表扫描，还是索引扫描，还是直接用rowid
- 表之间的连接类型
- 表之间的连接顺序
- 语句的并行程度

HINT只应用在他们所在sql语句块上，对于其他sql语句块没有影响。语法：

```sql
{ DELETE | INSERT | SELECT | UPDATE } /*+ hint [text] [hint [text]] */
-- 或者
{ DELETE | INSERT | SELECT | UPDATE } --+ hint [text] [hint[text]]
```

如果没有正确的指定Hints，数据库解析器会将HINT忽略，不报错。

### mysql上常用HINT

```sql
-- 强制索引 FORCE INDEX
SELECT * FROM `t_test` /*! FORCE INDEX (field1 ...) */;
-- 忽略索引 IGNORE INDEX
SELECT * FROM t_test /*! IGNORE INDEX (field1 ...) */;
-- 关闭查询缓冲 SQL_NO_CACHE
SELECT /*! SQL_NO_CACHE */ field1, field2 FROM `t_test`;
-- 强制查询缓冲 SQL_CACHE
SELECT /*! SQL_CACHE */ field1, field2 FROM `t_test`;
-- 优先操作 HIGH_PRIORITY (可以用select和insert上)
SELECT /*! HIGH_PRIORITY */ * FROM `t_test`;
-- 滞后操作 LOW_PRIORITY
SELECT /*! LOW_PRIORITY */ * FROM `t_test`;
-- 延迟插入 INSERT DELAYED
INSERT /*! DELAYED */ INTO `t_test` VALUES (value1, value2 ..);
-- 强制连接顺序 STRAIGHT_JOIN
SELECT `t_test1`.`field1`, `t_test2`.`field2` FROM `t_test1` /*! STRAIGHT_JOIN */ `t_test2` WHERE ..
-- 强制使用临时表 SQL_BUFFER_RESULT
SELECT /*! SQL_BUFFER_RESULT */ * FROM TABLE1 WHERE
-- 分组使用临时表 SQL_BIG_RESULT和SQL_SMALL_RESULT，多用于分组或DISTINCT关键字
```
