use master

if exists(select * from sys.databases where Name='Session15')
drop database Session15
go

create database Session15

use Session15

--PART 2:

create table Toys ( 
    ProductCode varchar(5) primary key,
	Name varchar(30) not null,
	Category varchar(30) not null,
	Manufactures varchar(40) not null,
	AgeRange varchar(15) not null,
	UnitPrice money constraint CheckPrice check (UnitPrice > 0),
	Netweight int constraint CheckWeight check (NetWeight > 100),
	QtyOnHand int 
)

--1: thêm 15 bản ghi vói giá trị QtyHand min 20

insert into Toys values
   (1, 'Bo lap ghep', 'Lap ghep', 'A' , '3-12', 100, 800, 20), 
   (2, 'Bo xe do choi lap ghep', 'Lap ghep', 'A' , '3-12', 120, 1200, 21),
   (3, 'Bo nha bup be lap ghep', 'Lap ghep', 'A' , '3-12', 150, 1500, 20),
   (4, 'Bo xe do choi lap ghep', 'Lap ghep', 'B' , '6-15', 100, 1800, 25),

   (5, 'Dat nan nho', 'Dat nan', 'A' , '5-12', 79, 200, 20),
   (6, 'Dat nan vua', 'Dat nan', 'A' , '5-12', 119, 400, 23),
   (7, 'Dat nan lon', 'Dat nan', 'A' , '5-12', 149, 700, 20),
   (8, 'Bo cau do', 'bo cau do', 'A' , '5-12', 99, 400, 20),
   (9, 'Bo game', 'Bo game', 'A' , '5-12', 199, 600, 80),
   (10, 'Bup be', 'Bup be', 'A' , '5-12', 189, 500, 20),
   (11, 'Sap mau 12 mau', 'Sap mau', 'A' , '5-12', 50, 200, 20),
   (12, 'Sap mau 24 mau', 'Sap mau', 'A' , '5-12', 80, 500, 20),
   (13, 'Sap mau 48 mau', 'Sap mau', 'A' , '5-12', 100, 700, 20),
   (14, 'Mau nuoc 12 mau', 'Mau nuoc ', 'A' , '5-12', 50, 300, 20),

   (15, 'Mau nuoc 24 mau', 'Mau nuoc', 'A' , '5-12', 80, 400, 20)

select * from Toys


--2: Viết lệnh tạo thủ tục lưu trữ là HeavyToy cho phép liệt kê tất cả các
--loại đồ chơi có trọng lượng > 500 g


create PROCEDURE HeavyToy
as
begin 

   select * from Toys 
   where Netweight >= 500

end

exec HeavyToy

--3: PriceIncrease cho phép tăng giá all đồ chơi lên 10 đon vị gía

create procedure PriceIncrease 
as
begin
    update Toys
	set UnitPrice += 10

	select * from Toys
 
end

drop procedure PriceIncrease

exec PriceIncrease
go

select * from Toys

--4: QtyOnHand là giảm số lượng đồ chơi xuống 5 đơn vị

create procedure QtyHand
as 
begin
    update  Toys
    set QtyOnHand -= 5

	select * from Toys
end

drop procedure QtyHand
exec QtyHand 
go

select * from Toys

-- PART 3:

--1: viết câu lệnh xem dịnh nghĩa các thủ tục lưu trữ vói 3 cách sau:
-- sp_helptext
-- sys.sql_modules
-- object_definition()

exec sp_helptext 'PriceIncrease'

exec sp_helptext 'QtyHand'



 SELECT 
          sm.object_id
        , ss.[name] as [schema]
        , o.[name] as object_name
        , o.[type]
        , o.[type_desc]
        , sm.[definition]  
FROM sys.sql_modules AS sm     
JOIN sys.objects AS o 
    ON sm.object_id = o.object_id  
JOIN sys.schemas AS ss
    ON o.schema_id = ss.schema_id  
ORDER BY 
      o.[type]
    , ss.[name]
    , o.[name]
	
select object_definition(object_id('PriceIncrease')) as [Procedure Definition]


--2: viết câu lệnh hiển thi đối tựong phụ thuộc của mỗi thủ tục lưu trữ
SELECT SCHEMA_NAME(schema_id) AS schema_name
    ,o.name AS object_name
    ,o.type_desc
    ,p.parameter_id
    ,p.name AS parameter_name
    ,TYPE_NAME(p.user_type_id) AS parameter_type
    ,p.max_length
    ,p.precision
    ,p.scale
    ,p.is_output
FROM sys.objects AS o
INNER JOIN sys.parameters AS p ON o.object_id = p.object_id
WHERE o.object_id = OBJECT_ID('QtyHand')
ORDER BY schema_name, object_name, p.parameter_id;
GO


--3: PriceIncrease và QtyHand thêm câu lệnh hiển thị giá mới đã được cập nhật 


alter procedure PriceIncrease
as
begin 
   update Toys
	set UnitPrice += 10
	select 
	   Toys.ProductCode, 
	   Toys.Name,
	   Toys.Category,
	   Toys.Manufactures,
	   Toys.AgeRange, 
	   Toys.UnitPrice - 10 as PriceOld,
	   Toys.UnitPrice as NewPrice,
	   Toys.Netweight,
	   Toys.QtyOnHand
	from Toys  
	
end

exec PriceIncrease

alter procedure QtyHand
as
begin
  update Toys
  set 
    QtyOnHand -= 5
  where
    QtyOnHand >= 5
  

  select 
     Toys.ProductCode, 
	 Toys.AgeRange,
	 Toys.Category,
	 Toys.Name,
	 Toys.QtyOnHand + 5 as QtyOld,
	 Toys.QtyOnHand as QtyNew

  from Toys
  
end

exec QtyHand

--4: viết câu lệnh tạo store procedure là SpecificPriceIncrease
-- thực hiện cộng thêm tổng số sản phầm (giá trị trường QtyOnHand)
-- vào giá của sản phảm đồ chơi tương ứng

select * from Toys

create procedure SpecificPriceIncrease
as
begin
select t.name,
       t.ProductCode,
	   t.UnitPrice,
	   t.QtyOnHand,
	   t.UnitPrice * t.QtyOnHand as SumPrice

from Toys  as t
end

exec SpecificPriceIncrease


--5: chỉnh sửa SpecificPriceIncrease cho thêm tính năng tính lại tổng số 
-- bản ghi đươc cập nhật

alter procedure SpecificPriceIncrease
as 
begin
select t.name,
       t.ProductCode,
	   t.UnitPrice,
	   t.QtyOnHand,
	   t.UnitPrice * t.QtyOnHand as SumPrice,
	   count(*) as RecordUpdate

from Toys  as t
group by t.name, t.ProductCode, t.UnitPrice, T.QtyOnHand
end

--6: chỉnh sửa SpecificPriceIncrease cho phép gọi thủ tục HeavyToys trong nó

alter procedure SpecificPriceIncrease
as 
begin
  
   
  select t.name,
       t.ProductCode,
	   t.UnitPrice,
	   t.QtyOnHand,
	   t.UnitPrice * t.QtyOnHand as SumPrice,
	   t.Netweight,
	   count(*) as RecordUpdate
	   
from  Toys as t
where t.ProductCode in ( select Toys.ProductCode 
                          from Toys
						  where Toys.Netweight >= 500)
group by t.name, t.ProductCode, t.UnitPrice, t.QtyOnHand , t.Netweight
    
end

exec SpecificPriceIncrease