-- create DDL scripts for CSV files in CRM and ERP systems

drop table silver.crm_cst_info;
create or replace table silver.crm_cst_info(
    cst_id INT,
    cst_key VARCHAR(50),
    cst_first_name varchar(50),
    cst_lastname varchar(50),
    cst_material_status varchar(50),
    cst_gndr varchar(50),
    cst_create_date DATE,
    dwh_create_date date DEFAULT current_date
);


drop table silver.crm_prd_info;
create or replace table silver.crm_prd_info(
    prd_id INT,
    cat_id varchar(50),
    prd_key VARCHAR(50),
    prd_nm VARCHAR(50),
    prd_cost INT,
    prd_line VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE,
    dwh_create_date date DEFAULT current_date
);


drop table silver.crm_sales_info;
create or replace table silver.crm_sales_info(
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_cust_id INT,
    sls_order_dt DATE,
    sls_ship_dt DATE,
    sls_due_dt DATE,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT,
    dwh_create_date date DEFAULT current_date
);

drop table silver.erp_cst_az12;
create or replace table silver.erp_cst_az12(
    cid varchar(50),
    bdate DATE,
    gen  varchar(50),
    dwh_create_date date DEFAULT current_date
);

drop table silver.erp_loc_a101;
create or replace table silver.erp_loc_a101(
    cid varchar(50),
    cntry varchar(50),
    dwh_create_date date DEFAULT current_date
);


drop table silver.erp_px_cat_g1v2;
create or replace table silver.erp_px_cat_g1v2(
    id varchar(50),
    cat varchar(50),
    subcat varchar(50),
    maintenance varchar(50),
    dwh_create_date date DEFAULT current_date
);

---------------------------------------------------------------------------------------

-- Creating Stored Procedure

CREATE OR REPLACE PROCEDURE silver.etl_silver()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_customers_loaded NUMBER;
    v_products_loaded NUMBER;
    v_sales_loaded NUMBER;
    v_erp_cst_loaded NUMBER;
    v_erp_loc_loaded NUMBER;
    v_erp_px_cat_loaded NUMBER;
BEGIN
    -- truncate the tabels
    truncate table silver.crm_cst_info;
    truncate table silver.crm_prd_info;
    truncate table silver.crm_sales_info;
    truncate table silver.erp_cst_az12;
    truncate table silver.erp_loc_a101;
    truncate table silver.erp_px_cat_g1v2;
   
    -- inserting data into silver.crm_cst_info table 
    insert into silver.crm_cst_info(
        cst_id,
        cst_key,
        cst_first_name,
        cst_lastname,
        cst_material_status,
        cst_gndr,
        cst_create_date)
    select 
        cst_id,cst_key,
        trim(cst_first_name) cst_first_name,
        trim(cst_lastname) cst_lastname,
        case upper(trim(cst_material_status))
            when 'M' then 'Married'
            when 'S' then 'Single'
            else 'N/A'
        end cst_material_status, -- normalize marital status to readable value
        case upper(trim(cst_gndr))
            when 'F' then 'Female'
            when 'M' then 'Male'
            else 'N/A'
        end cst_gndr, -- normalize gender to readable value
        cst_create_date
    from (
    select 
        *, row_number() over(partition by cst_id order by cst_create_date desc) as flag
    from bronze.crm_cst_info
    where cst_id is not null
    )t where flag =1; -- selects the latest record per customer
    
    --create table v_customers_loaded AS (select count(*) from silver.crm_cst_info);
    ----------------------------------------------------------------------------------
    -- inserting data into silver.crm_prd_info table
    
    insert into silver.crm_prd_info(
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt)
    select 
        prd_id,
        replace(substr(prd_key,1,5),'-','_') cat_id, -- extract catageory ID
        substr(prd_key,7,len(prd_key)) as prd_key, -- extract product key
        trim(prd_nm) prd_nm, -- removing spaces if any
        IFNULL(prd_cost,0) prd_cost, --removing nulls 
        case upper(trim(prd_line))
            when 'M' then 'Mountain'
            when 'R' then 'Road'
            when 'S' then 'Other Sales'
            when 'T' then 'Touring'
            else 'N/A'
        end prd_line, -- map product line codes to descriptive values
        cast(prd_start_dt as DATE) prd_start_dt, -- data type casting 
        cast(dateadd('day', -1, lead(prd_start_dt) over(partition by prd_key order by prd_start_dt asc)) as DATE) prd_end_dt 
        -- calculate the end date as one day before the next start date and type casting to date
    from bronze.crm_prd_info;
    
     --create table v_products_loaded AS (select count(*) from silver.crm_prd_info);
     ----------------------------------------------------------------------------------
     -- inserting data into silver.crm_sales_info table

    insert into silver.crm_sales_info(
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price)
    select 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        case 
            when sls_order_dt=0 or len(sls_order_dt) !=8  then NULL
            else cast(cast(sls_order_dt as varchar) as DATE)
        end sls_order_dt,
        case 
            when sls_ship_dt =0 or len(sls_ship_dt) !=8  then NULL
            else cast(cast(sls_ship_dt as varchar) as DATE)
        end sls_ship_dt,
        case 
            when sls_due_dt=0 or len(sls_due_dt) !=8  then NULL
            else cast(cast(sls_due_dt as varchar) as DATE)
        end sls_due_dt,
        case when sls_sales IS NULL or sls_sales <=0 or sls_sales != sls_quantity *ABS(sls_price)
                then sls_quantity *ABS(sls_price)
             else sls_sales
        end sls_sales, -- Recalculate sales if the original value is missing or incorrect
        sls_quantity,
        case when sls_price is NULL or sls_price <= 0 then sls_sales/NULLIF(sls_quantity,0)
            else sls_price
        end sls_price -- Derive price if original value is invalid
    from bronze.crm_sales_info;
    
    --create table v_sales_loaded as (select count(*) from silver.crm_sales_info);
    ----------------------------------------------------------------------------------
    -- inserting data into silver.erp_cst_az12 table
    
    insert into silver.erp_cst_az12(
        cid,
        bdate,
        gen)
    select 
        case when cid like 'NAS%' then substr(cid,4,len(cid))
             else cid 
        end cid, -- Removed 'NAS' prefox if present
        case when bdate > current_date() then NULL
             else bdate
        end bdate, -- set future birthdays to NULL
        case 
            when upper(trim(gen)) IN ('M','Male') then 'Male'
            when upper(trim(gen)) IN ('F','Female') then 'Female'
            else 'N/A'
        end gen -- Normalized gender values and handled unknown values
    from bronze.erp_cst_az12;
    
    --create table v_erp_cst_loaded as (select count(*) FROM silver.erp_cst_az12);
    ----------------------------------------------------------------------------------
    -- inserting data into the silver.erp_loc_a101 table 
    
    insert into silver.erp_loc_a101(
        cid,
        cntry)
    select 
        replace(cid,'-','') cid, -- handled invalid vales
        case when upper(trim(cntry)) IN ('USA','US') then 'United States'
             when upper(trim(cntry)) IN('DE') then 'Germany'
             when trim(cntry) = '' or cntry is null then 'N/A'
             else trim(cntry)
        end cntry --normalized and handled missing or blank spaces
    from bronze.erp_loc_a101;
    
     --create table v_erp_loc_loaded as (select count(*) FROM silver.erp_loc_a101);
    ----------------------------------------------------------------------------------
    -- inserting data into the silver.erp_px_cat_g1v2 table 
    
    insert into silver.erp_px_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance)
    
    select 
        id,
        cat,
        subcat,
        maintenance
    from bronze.erp_px_cat_g1v2;
    
     --create table v_erp_px_cat_loaded as (select count(*) FROM silver.erp_px_cat_g1v2);
     ----------------------------------------------------------------------------------

    RETURN 'ETL Completed Successfully!';
END;
$$;


CALL etl_silver();

select * from silver.crm_cst_info; --18.5k records
select * from silver.crm_prd_info; --18.5k records
select * from silver.crm_sales_info; --60.4k records
select * from silver.erp_cst_az12; --18.5k records
select * from silver.erp_loc_a101; --18.5k records
select * from silver.erp_px_cat_g1v2; --37 records
