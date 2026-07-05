-- 1. customer_id = 1001 olan müştərinin son 6 ayda etdikləri əməliyyatların ümumi məbləği haqqın informasiyanı təyin edən sorğunu
--    yazın.

select sum(t.amount)||' ' ||'azn' as ümumi_məbləğ
from transactions t
join accounts a on t.account_id = a.account_id
where a.customer_id = 1001
and t.transaction_date >= (select add_months(max(transaction_date), -6) from transactions);
        
-- 2. Hər müştərinin hesablarında olan ümumi balansı və aktiv kredit məbləğini göstərmək
select c.customer_id as müştəri_id, 
       sum(a.balance) as ümumi_balans,
       (select sum(l.loan_amount) from loans l where l.customer_id = c.customer_id) ||' ' ||'azn' as ümumi_kredit
from customers c
left join accounts a on c.customer_id = a.customer_id
group by c.customer_id;

-- 3. Aktiv depoziti olan müştərilərin depozit və kredit məlumatlarının siyahısını çıxarmaq:  
select d.customer_id as müştəri_id, 
       d.deposit_amount ||' ' ||'azn' as depozit_məbləği, 
       d.interest_rate ||'' ||'%'as depozit_faizi,
       l.loan_amount ||' ' ||'azn' as kredit_məbləği, 
       l.interest_rate||'' ||'%' as kredit_faizi
from deposits d
left join loans l on d.customer_id = l.customer_id
where d.end_date > (select max(transaction_date) from transactions);
          
-- 4. Hər müştərinin son 1 ildə açdığı bütün hesabları və bu hesablara görə edilən əməliyyatların ümumi məbləğini göstərmək:
    select a.customer_id as müştəri_id, 
    a.account_id as hesab_nömrəsi, 
    sum(t.amount)||' ' ||'azn' as ümumi_məbləğ
from accounts a
left join transactions t on a.account_id = t.account_id
where a.date_opened >= (select add_months(max(transaction_date), -12) from transactions)
group by a.customer_id, a.account_id;
      
-- 5. Hər müştərinin son 1 ildə etdikləri əməliyyatların növlərinə görə ümumi məbləğini göstərmək: 
select a.customer_id as müştəri_id,
       t.transaction_type as tranzaksiya_növü, 
       sum(t.amount)||' ' ||'azn' as ümumi_tranzaksiya_məbləği
from transactions t
join accounts a on t.account_id = a.account_id
where t.transaction_date >= (select add_months(max(transaction_date), -12) from transactions)
group by a.customer_id, t.transaction_type;
      
-- 6. Hər müştəri üçün son 6 ayda əməliyyatların ən yüksək məbləğli əməliyyatını təyin edən sorğu yazın:
select a.customer_id as müştəri_id, 
max(t.amount)||' ' ||'azn' as max_məbləğ
from transactions t
join accounts a on t.account_id = a.account_id
where t.transaction_date >= (select add_months(max(transaction_date), -6) from transactions)
group by a.customer_id;
     
-- 7. Hər müştəri üçün son 1 il ərzində hər ay üzrə ümumi balans və depozit məbləğini göstərmək üçün sorğu yazın:
  select a.customer_id as müştəri_id, 
         to_char(t.transaction_date, 'yyyy-mm') as tarix, 
         sum(a.balance) as ümumi_balans, 
         sum(d.deposit_amount)||' ' ||'azn' as ümumi_depozit
from accounts a
left join deposits d on a.customer_id = d.customer_id
join transactions t on a.account_id = t.account_id
where t.transaction_date >= (select add_months(max(transaction_date), -12) from transactions)
group by a.customer_id, to_char(t.transaction_date, 'yyyy-mm');
     
-- 8. Hər müştərinin son 3 ay ərzində hər bir aya görə ən çox əməliyyat edən hesabının məbləğini göstərmək.
with son_tarix as (select max(transaction_date) as max_tarix from transactions),
aylıq_əməliyyatlar as (
    select 
        a.customer_id as müştəri_id ,
        t.account_id as hesab_nömrəsi,
        to_char(t.transaction_date,'yyyy-mm') as il_ay,
        count(*) as əməliyyat_sayı
    from transactions t
    join accounts a on t.account_id = a.account_id
    join son_tarix st on 1=1
    where t.transaction_date >= add_months(st.max_tarix,-3)
    group by a.customer_id, t.account_id, to_char(t.transaction_date,'yyyy-mm')),
ranked as (
    select aə.*,
           row_number() over(partition by müştəri_id, il_ay order by əməliyyat_sayı desc) as rn
    from aylıq_əməliyyatlar aə)
select *
from ranked
where rn = 1;
     
-- 9. Hər müştərinin son 3 ay ərzində müştərilərin ünvanlarına görə hər ay ümumi balansını və ünvanın tipini göstərmək.
with son_tarix as (select max(transaction_date) as max_tarix from transactions)
select
    c.customer_id as müştəri_id,
    to_char(a.date_opened,'yyyy-mm') as il_ay,
    at.type_name as tranzaksiya_növü,
    sum(a.balance) as ümumi_balans
from accounts a
join customers c on a.customer_id = c.customer_id
join address ad on c.customer_id = ad.customer_id
join address_type at on ad.type_id = at.type_id
join son_tarix st on 1=1
where a.date_opened >= add_months(st.max_tarix,-3)
group by c.customer_id, to_char(a.date_opened,'yyyy-mm'), at.type_name;
        
-- 11. Hər müştərinin son 1 il ərzində ən çox əməliyyat edilən günü göstərmək. 
with son_tarix as (select max(transaction_date) as max_tarix from transactions),
günlük_əməliyyatlar as (
    select 
        a.customer_id as müştəri_id,
        trunc(t.transaction_date) as günlük_əməliyyatlar,
        count(*) as əməliyyat_sayı
    from transactions t
    join accounts a on t.account_id = a.account_id
    join son_tarix st on 1=1
    where t.transaction_date >= add_months(st.max_tarix,-12)
    group by a.customer_id, trunc(t.transaction_date)),
ranked as (
    select g.*,
           row_number() over(partition by  müştəri_id order by əməliyyat_sayı desc) as rn
    from günlük_əməliyyatlar g)
select *
from ranked
where rn = 1;
                                      
-- 12. Son 6 ayda ən yüksək kredit məbləğinə sahib olan müştəri haqqında məlumatlar və kredit məbləğini göstərmək.
with son_tarix as (select max(transaction_date) as max_tarix from transactions)
select *
from (
    select
        l.customer_id as müştəri_id,
        l.loan_id as kredit_nömrəsi,
        l.loan_amount||' ' ||'azn' as kredit_məbləği,
        row_number() over(order by l.loan_amount desc) as rn
    from loans l
    join son_tarix st on 1=1
    where l.start_date >= add_months(st.max_tarix,-6))
where rn = 1;
   
-- 13. Son 1 il ərzində hər müştəri üçün ən çox balans artımı olan ayı göstərmək.
select customer_id as müştəri_id, 
month from (
    select a.customer_id, 
           to_char(t.transaction_date, 'fmmonth') as month , 
           sum(t.amount) as ümumi_məbləğ,
           rank() over(partition by a.customer_id order by sum(t.amount) desc) as rnk
    from transactions t
    join accounts a on t.account_id = a.account_id
    where t.transaction_type in ('Deposit', 'Transfer') 
    and t.transaction_date >= (select add_months(max(transaction_date), -12) from transactions)
    group by a.customer_id, to_char(t.transaction_date, 'fmmonth')) where rnk = 1;

      
-- 14. Hər müştərinin son 1 il ərzində ən çox istifadə edilən əməliyyat növlərini və həmin növlərə görə əməliyyatların sayını 
--     göstərmək.  
select a.customer_id as müştəri_id, 
       t.transaction_type as tranzaksiya_növü, 
       count(*) as say
from transactions t
join accounts a on t.account_id = a.account_id
where t.transaction_date >= (select add_months(max(transaction_date), -12) from transactions)
group by a.customer_id, t.transaction_type;
   
-- 15. Son 6 ay ərzində hər müştərinin ən uzun müddətli aktif kreditini tapmaq.
select customer_id as müştəri_id, 
       loan_id as kredit_nömrəsi, 
       (end_date - start_date) as müddət
from loans
where start_date >= (select add_months(max(transaction_date), -6) from transactions)
and end_date > (select max(transaction_date) from transactions)
order by müddət desc;
            
-- 16. Son 1 il ərzində hər müştərinin hər ay ən çox balansı olan hesabını göstərmək. 
with son_tarix as (select max(transaction_date) as max_tarix from transactions),
aylıq_balans as (
    select
        customer_id as müştəri_id,
        account_id as hesab_nömrəsi,
        to_char(date_opened,'yyyy-mm') as il_ay,
        balance as balans
    from accounts
    join son_tarix st on 1=1
    where date_opened >= add_months(st.max_tarix,-12)),
ranked as (
    select 
        ab.*,
        row_number() over(partition by müştəri_id, il_ay order by balans desc) as rn
    from aylıq_balans ab)
select *
from ranked
where rn = 1;
    
   

     




  
