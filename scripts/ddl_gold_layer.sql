
-- creating the gold layers based on the silver layer

create or replace VIEW gold.dim_customers as(
    
    select 
        row_number() over(order by ci.cst_id) customer_key,
        ci.cst_id customer_id,
        ci.cst_key customer_number,
        ci.cst_first_name first_name,
        ci.cst_lastname last_name,
        ci.cst_material_status marital_status,
        ca.bdate birthdate,
        case 
              when lower(ci.cst_gndr) != 'n/a' then ci.cst_gndr -- crm is the master for gender info
              else coalesce(ca.gen,'N/A')
         end as gender,
        ce.cntry country,
        ci.cst_create_date create_date
    from silver.crm_cst_info ci
    LEFT JOIN silver.erp_cst_az12 ca 
    on ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101 ce
    on ci.cst_key = ce.cid
);


select distinct(gender) from gold.dim_customers; -- 3 unique records
----------------------------------------------------------------------------------------

create or replace VIEW gold.dim_products as (

    select 
        row_number() over(order by p.prd_start_dt,p.prd_key) product_key,
        p.prd_id product_id,
        p.prd_key product_number,
        p.prd_nm product_name,
        p.cat_id category_id,
        pc.cat category,
        pc.subcat subcategory,
        pc.maintenance,
        p.prd_cost cost,
        p.prd_line product_line,
        p.prd_start_dt start_line
    from silver.crm_prd_info p
    left join silver.erp_px_cat_g1v2 pc
    on p.cat_id = pc.id
    where prd_end_dt IS NULL-- filter out all historical data
);

select * from gold.dim_products;
-----------------------------------------------------------------------------------------
-- creating the fact table from the dimension tables

create or replace view gold.fact_sales as (
    select 
        s.sls_ord_num order_number,
        dp.product_key,
        dc.customer_key,
        s.sls_order_dt order_date,
        s.sls_ship_dt shipping_date,
        s.sls_due_dt due_date,
        s.sls_price price,
        s.sls_quantity quantity,
        s.sls_sales sales_amount
    from silver.crm_sales_info s
    left join gold.dim_products dp
    on s.sls_prd_key = dp.product_number
    left join gold.dim_customers dc
    on s.sls_cust_id = dc.customer_id
);

select * from gold.fact_sales;
