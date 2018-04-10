
--------------------------------------------
--use this code block to update comprehensive_data, 
--wiping out all previous tdg_conflate
--be careful; do not run this unles you need to rerun
--everything!!
--------------------------------------------

--drop table if exists comprehensive_data;

--create table received.comprehensive_data as 
--	select * from received.neighborhood_ways;

--add columns to comprehensive_data

--alter table comprehensive_data
--add column volume integer,
--add column speed integer,
--add column tot_lanes integer,
--add column parking_l integer,
--add column parking_r integer,
--add column funcclass varchar,
--add column oneway varchar,
--add column en_exist_bike varchar,
--add column ws_exist_bike varchar,

--add column en_bike_width integer,
--add column ws_bike_width integer,

--add column en_bike_buf integer,
--add column ws_bike_buf integer,

--add column en_rec_bike varchar,
--add column ws_rec_bike varchar
--add column city varchar
--; 

alter table comprehensive_data
add column city varchar; 


--------------------------------------------------------
--Use this code block to create a combined streets and combined bike layer
--this laye will eventually be merged to the comprehensive data
--using tdg_conflate
--------------------------------------------------------

---create combined  table for all street centerline data 
drop table if exists generated.combined_streets;
create table generated.combined_streets (
id serial primary key,
geom geometry (multilinestring, 26910),
volume integer,
speed integer,
tot_lanes integer,
parking_l integer,
parking_r integer,
funcclass varchar,
city varchar);

---create combined  table for bicycle data
drop table if exists generated.combined_bike;
create table generated.combined_bike (
id serial primary key,
geom geometry (multilinestring, 26910),
en_exist_bike varchar,
ws_exist_bike varchar,

en_bike_width integer,
ws_bike_width integer,

en_bike_buf integer,
ws_bike_buf integer,


en_rec_bike varchar,
ws_rec_bike varchar,

parking_l integer,
parking_r integer);

--------------------------------------------------
---update comprehensive_data with MMAP data, first, using tdg_conflate
-----

--------------------------------------------------------------------------------------------------------
--MMAP DATA
--- need to use tdg_conflate to update this in the comprehensvie dataset first,
--since all other streets data sets will essentially preempt MMAP; MMAP is only used to 'fill in the gaps' 
-------------------------------------------------------------------------------------------------------


--ALTER TABLE generated.mmap_alldata ADD geom2d geometry;
--UPDATE generated.mmap_alldata SET geom2d = ST_Force2D(geom);

--SELECT UpdateGeometrySRID('mmap_alldata','geom2d',26910);

--first, sum total number of lanes--

--alter table generated.mmap_alldata
--add column total_lanes integer;


update generated.mmap_alldata
set wbsbtl1 = CASE WHEN wbsbtl1 >0 and wbsbtl1 is not null then 1
			Else 0
			END,
	   wbsbtl2 = CASE WHEN wbsbtl2 >0 and wbsbtl2 is not null then 1
			Else 0
			END,
		wbsbtl3 = CASE WHEN wbsbtl3 >0 and wbsbtl3 is not null then 1
			Else 0
			END,
		wbsbtl4 = CASE WHEN wbsbtl4 >0 and wbsbtl4 is not null then 1
			Else 0
			END,
		ebnbtl1 = CASE WHEN ebnbtl1 >0 and ebnbtl1 is not null then 1
			Else 0
			END,
		ebnbtl2 = CASE WHEN ebnbtl2 >0 and ebnbtl2 is not null then 1
			Else 0
			END,
		ebnbtl3 = CASE WHEN ebnbtl3 >0 and ebnbtl3 is not null then 1
			Else 0
			END,
		ebnbtl4 = CASE WHEN ebnbtl4 >0 and ebnbtl4 is not null then 1
			Else 0
			END;

with t1 as ( select id, (wbsbtl1 + wbsbtl2 + wbsbtl2 + wbsbtl3 + wbsbtl4 + ebnbtl1 + ebnbtl2 + ebnbtl3 + ebnbtl4) as sum
	from generated.mmap_alldata
	group by id)
update generated.mmap_alldata as a
set total_lanes = t1.sum --if tot_lanes = 0, then that is the equivalent of NA 			
from t1
where t1.id = a.id;

--The following sequence updates comprehensive_data with mmap data
--ALTER TABLE comprehensive_data
--drop column conflation_buffer;
-- ADD COLUMN conflation_buffer geometry(multipolygon,26910);

-- bike facilties
--UPDATE comprehensive_data SET conflation_buffer = ST_Multi(ST_Buffer(ST_Buffer(geom,52,'endcap=flat'),-2))
--CREATE INDEX tsidx_buffgeom_comprehensive_data ON comprehensive_data USING GIST(conflation_buffer);
--ANALYZE comprehensive_data(conflation_buffer);

--use tdg_conflate to udpate comprehensive_data
--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='volume',
--    target_geom_:='geom',
--    source_table_:='mmap_alldata',
--    source_column_:='mean_adt_c',
--    source_geom_:='geom2d',
--    tolerance_:=3,
--  angle_:=30,
--    angle_buffer_:= 2,
--    source_filter_:='mean_adt_c >0 and mean_adt_c is not null',    -- where clause to filter the source data, if desired: NA for bike infra--
--   buffer_geom_:= 'conflation_buffer',
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=8
    --boundary_:= t.geom
 
--)
--from grid as t; 

--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='speed',
--    target_geom_:='geom',
--    source_table_:='mmap_alldata',
--    source_column_:='postedspee',
--    source_geom_:='geom2d',
--    tolerance_:=3,
--    angle_:=10,
--    angle_buffer_:= 10,
--    source_filter_:='postedspee >0 and postedspee is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=5
 --)

--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='tot_lanes', --udpate total lanes column
--    target_geom_:='geom',
--    source_table_:='mmap_alldata',
--    source_column_:='total_lanes',
--    source_geom_:='geom2d',
--    tolerance_:=30,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='total_lanes >0 and total_lanes is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=3,
--    boundary_:= t.geom,
--    buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 



--SELECT tdg_Conflate(
 --   target_table_:='comprehensive_data',
 --   target_column_:='parking_l', --update parking_l column
 --   target_geom_:='geom',
 --   source_table_:='mmap_alldata',
 --   source_column_:='wbsbparkin', --this is parking width
 --   source_geom_:='geom2d',
 --   tolerance_:=30,
 --   angle_:=10,
 --   angle_buffer_:= 12,
 --   source_filter_:='wbsbparkin >0 and wbsbparkin is not null',    -- where clause to filter the source data, if desired: NA for bike infra
 --   min_target_length_:=50,
 --   min_shared_length_pct_:=0.8,
 --   max_fill_gap_cycles_:=3
    --boundary_:= t.geom,
  -- buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 

--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='parking_r', --update parking_r column
--    target_geom_:='geom',
--    source_table_:='mmap_alldata',
--    source_column_:='ebnbparkin', --this is parking width for east/north
--    source_geom_:='geom2d',
--    tolerance_:=30,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='ebnbparkin >0 and ebnbparkin is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
--    buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 



--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='en_bike_width',
--    target_geom_:='geom',
--    buffer_geom_:= 'conflation_buffer',
--    source_table_:='mmap_alldata',
--    source_column_:='ebnbbikeln', --east bound/north bound bike lane width
--    source_geom_:='geom2d',
--    tolerance_:=50,
--    angle_:=10,
 --    angle_buffer_:= 12,
 --   source_filter_:='ebnbbikeln >0 and ebnbbikeln is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=2
    --boundary_:= t.geom
 
--)
--From grid_3mi
--;

--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='ws_bike_width',
--    target_geom_:='geom',
--    buffer_geom_:= 'conflation_buffer',
--    source_table_:='mmap_alldata',
--    source_column_:='wbsbbikeln', --west bound/south bound bike lane width
--    source_geom_:='geom2d',
--    tolerance_:=50,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='wbsbbikeln >0 and wbsbbikeln is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=2
    --boundary_:= t.geom
 
--)
--From grid_3mi
--;




---
--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='en_bike_buf',
    --target_geom_:='geom',
    --buffer_geom_:= 'conflation_buffer',
    --source_table_:='mmap_alldata',
    --source_column_:='ebnbbikebu', --east/north bound bike lane buffer width
    --source_geom_:='geom2d',
    --tolerance_:=50,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='ebnbbikebu >0 and ebnbbikebu is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.8,
  --  max_fill_gap_cycles_:=2
   --boundary_:= t.geom
 
--)
--From grid_3mi
--;

--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='ws_bike_buf',
    --target_geom_:='geom',
    --buffer_geom_:= 'conflation_buffer',
    --source_table_:='mmap_alldata',
    --source_column_:='wbsbbikebu', --west/south bound bike lane buffer width
    --source_geom_:='geom2d',
    --tolerance_:=50,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='wbsbbikebu >0 and wbsbbikebu is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.8,
  --  max_fill_gap_cycles_:=2
   -- boundary_:= t.geom
 
--);
--



--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='en_rec_bike',
--    target_geom_:='geom',
--    buffer_geom_:= 'conflation_buffer',
--    source_table_:='mmap_alldata',
--    source_column_:='impbikecla',
--    source_geom_:='geom2d',
--    tolerance_:=30,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='impbikecla is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=2
--    boundary_:= t.geom
 
--);

--From grid_3mi;


--can simply use update/set to updat wb_rec_bike based on en_rec_bike, since bike improvement recommendations
-- don't differentiate between sides of street

--update comprehensive_data
--set ws_rec_bike = en_rec_bike; 

-------------------
----Pleasanton DATA---
-------------------
alter table pleasanton_centerline
add column city varchar;

update pleasanton_centerline
set city = 'pleasanton';

insert into generated.combined_streets (geom, speed, tot_lanes, funcclass, city)

select geom,
dispatchsp,
numberofla,
functional,
city

from pleasanton_centerline;
	
--create a flag for parking from bikeways file for parking
alter table pleasanton_bikeways
add column parking_flag int;

update pleasanton_bikeways
set parking_flag= 1
where typeofbike like '%with Parking%';

update pleasanton_bikeways
set hasbuffere= case when 'YES' then 1
			else 0
			end; 




alter table pleasanton_bikeways
alter column hasbuffere type integer
USING hasbuffere::integer;

insert into generated.combined_bike(geom, ws_exist_bike, en_exist_bike, en_bike_buf, ws_bike_buf, parking_l, parking_r)

select geom,
bikewaycla,
bikewaycla,
hasbuffere,
hasbuffere,
parking_flag,
parking_flag

from pleasanton_bikeways; 



-------------------
----Dublin DATA---
-------------------

--first, add ADT to dublin centerline file

alter table generated.dublin_streetlines
add column adt integer;

update generated.dublin_streetlines as a
set adt = b.traffic_vo
from generated.dublin_volume as b
where st_dwithin(a.geom, b.geom, 30); 

alter table dublin_streetlines
add column city varchar;

update dublin_streetlines
set city = 'dublin';


--pull functional class, dispatch speed, number of lanes 
insert into generated.combined_streets(geom, speed, tot_lanes, volume, funcclass, city)

select geom,
dispatchsp,
numberofla,
adt,
functional,
city

from dublin_streetlines;

--clean dublin bike dataset 
alter table dublin_bike_rec
add column exist varchar;

update dublin_bike_rec
set exist = CASE WHEN trailtyp2 like '%Class II, Existing%' then 'Class II'
		WHEN trailtyp2 like '%Class I, Existing%' then 'Class I'
		WHEN trailtyp2 like '%Class III, Existing%' then 'Class III'
		Else null
		end;

		
alter table dublin_bike_rec
add column prop varchar;

update dublin_bike_rec
set prop = CASE WHEN trailtyp2 like '%Class II, Proposed%' then 'Class II'
		WHEN trailtyp2 like '%Class I, Proposed%' then 'Class I'
		WHEN trailtyp2 like '%Class III, Proposed%' then 'Class III'
		Else null
		end;

--update bike data
insert into combined_bike (geom, en_exist_bike,
			    ws_exist_bike,
			    en_rec_bike,
			    ws_rec_bike)
select geom,
exist,
exist,
prop,
prop

from dublin_bike_rec; 

-------------------
----Berkeley DATA---
-------------------

--update street data---

alter table berkeley_traffic_volume
add column city varchar;


update berkeley_traffic_volume
set city = 'berkeley';

insert into combined_streets (geom, speed, volume, tot_lanes, city, parking_l, parking_r)
select st_force2d(geom),
speed,
total,
lanes,
city,
parking,
parking
from berkeley_traffic_volume;


---update bicycle data---
insert into combined_bike (geom, en_exist_bike,
					ws_exist_bike)
Select st_force2d(geom),
existing_a,
existing_a

from berkeley_exist; 


insert into combined_bike (geom, en_rec_bike,
			    ws_rec_bike)

select st_force2d(geom),
"type",
"type"

from berkeley_rec;

	

---------------------------
---LIVERMORE DATA UPDATE----
---------------------------
alter table livermore_streets
add column city varchar;


update livermore_streets
set city = 'livermore';

--first, add ADT to livermore centerline file

alter table generated.livermore_streets
add column adt integer;

update generated.livermore_streets as a
set adt = b.avgdailycount
from generated.livermore_trafficcounts as b
where st_dwithin(a.geom, b.geom, 30); 

alter table generated.livermore_streets
add column exist_bike varchar; 


--udpate combined dataset with livermore data
insert into generated.combined_streets (geom, speed, tot_lanes, funcclass,city)

select geom,
dispatchsp,
numberofla, 	
functional,
city

from generated.livermore_streets; 

--udpate combined bike dataset with livermore data
insert into generated.combined_bike (geom, en_exist_bike, ws_exist_bike)

select geom,
trailtype,
trailtype

from generated.livermore_exist_bike; 

insert into generated.combined_bike (geom, en_rec_bike, ws_rec_bike)

select geom,
facilityty,
facilityty

from generated.livermore_rec_bike; 

----------------------
---SAN LEANDRO DATA---
----------------------
alter table sanleandro_centerlines
add column city varchar;


update sanleandro_centerlines
set city = 'san leandro';

--update combined dataset with San Leandro geometry and speed

insert into generated.combined_streets(geom, speed, funcclass, city)

select geom,
speedlimit,
"class",
city

from generated.sanleandro_centerlines; 

--update combined bike with San Leandro geometry, existing and recommended

insert into generated.combined_bike(geom, en_exist_bike, ws_exist_bike, en_rec_bike, ws_rec_bike)

select geom,
existing,
existing,
recommenda,
recommenda

from generated.sanleandro_recommend_exist_bike; 

-------------------
----OAKLAND DATA---
-------------------

----------------------
alter table oakland_lts_data
add column city varchar;


update oakland_lts_data
set city = 'oakland';

insert into generated.combined_streets(geom, speed, parking_l, parking_r, tot_lanes)

select geom,
prk_wid_l, --this is parking width
prk_wid_r,
posted_spd,
lanes_l + lanes_r

from oakland_lts_data;



--insert bike data from oakland lts dataset into combined_bike
insert into generated.combined_bike(geom, en_exist_bike,
					ws_exist_bike,

					en_bike_width,
					ws_bike_width,

					en_bike_buf,
					ws_bike_buf)
select geom,
bike_fac_l,
bike_fac_r,
bike_wd_l,
bike_wd_r,
bike_buf_l,
bike_buf_r

from oakland_lts_data;




--------------------------------------
--City of Alameda
--------------------------------------
alter table city_alameda_bike
add column city varchar;


update city_alameda_bike
set city = 'alameda';

insert into combined_streets (geom, funcclass, city)
select geom, 
"class",
city
from city_alameda_bike;

insert into combined_bike (geom, en_exist_bike,
				ws_exist_bike,
				en_rec_bike,
				ws_rec_bike)
Select geom,
bikeexist,
bikeexist,
bikeway,
bikeway

from city_alameda_bike; 

--------------------------------------
--City of Hayward
--------------------------------------
alter table hayward_centerlines
add column city varchar;

update hayward_centerlines
set city = 'hayward';

insert into combined_streets (geom, city, speed, funcclass)
select geom,
city,
speed,
functioncl

from hayward_centerlines;

insert into combined_bike (geom, en_exist_bike, ws_exist_bike)
select geom,
bicyclenet,
bicyclenet
from hayward_bike
where bicyclen_1 = 'Existing';

insert into combined_bike (geom, en_rec_bike, ws_rec_bike)
select geom,
bicyclenet,
bicyclenet
from hayward_bike
where bicyclen_1 = 'Proposed';

--------------------------------------
--City of Fremont
--------------------------------------
alter table fremont_street
add column city varchar;

update fremont_street
set city = 'freemont';

insert into combined_streets (geom, city, funcclass)
select geom,
city,
st_class
from fremont_street;

insert into combined_streets (geom, volume)
select st_multi(geom),
avg_adt2
from fremont_traffic
;



-------------------------------------------
--use tdg_conflate on combined_streets dataset
-------------------------------------------
--volume
--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--     target_column_:='volume',
--     target_geom_:='geom',
--     source_table_:='combined_streets',
--     source_column_:='volume',
--     source_geom_:='geom',
--     tolerance_:=30,
-- 	angle_:=10,
--    angle_buffer_:= 12,
 --    source_filter_:='volume >0 and volume is not null',    -- where clause to filter the source data, if desired: NA for bike infra--
 --   buffer_geom_:= 'conflation_buffer',
--     min_target_length_:=50,
--     min_shared_length_pct_:=0.8,
--     max_fill_gap_cycles_:=2
    --boundary_:= t.geom

--          );
--from grid_3mi as t; 

--speed
--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='speed',
--    target_geom_:='geom',
--    buffer_geom_:= 'conflation_buffer',
--    source_table_:='combined_streets',
--    source_column_:='speed',
--    source_geom_:='geom',
--    tolerance_:=50,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='speed >0 and speed is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=2,
--   boundary_:= t.geom

--         )
--from grid_3mi as t; 



--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='tot_lanes', --udpate total lanes column
--    target_geom_:='geom',
--    source_table_:='combined_streets',
--    source_column_:='tot_lanes',
--    source_geom_:='geom',
--    tolerance_:=50,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='tot_lanes >0 and tot_lanes is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=2,
--    boundary_:= t.geom,
--    buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 

----------------------------------------------------------------------------------
--parking left
--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='parking_l', --update parking_l width column
--    target_geom_:='geom',
--    source_table_:='combined_streets',
--    source_column_:='parking_l', --this is parking presence
--    source_geom_:='geom',
--    tolerance_:=50,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='parking_l >0 and parking_l is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=1,
--    boundary_:= t.geom,
--    buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 



---- parking right
--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='parking_r', --update parking_r width column
--    target_geom_:='geom',
--    source_table_:='combined_streets',
--    source_column_:='parking_r', --this is parking presence
--    source_geom_:='geom',
--    tolerance_:=50,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='parking_r >0 and parking_r is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=1,
--    boundary_:= t.geom,
--    buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t
--; 

---- functional class
--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='funcclass', 
--    target_geom_:='geom',
--    source_table_:='combined_streets',
--    source_column_:='funcclass', 
--    source_geom_:='geom',
--    tolerance_:=52,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='funcclass is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.7,
--    max_fill_gap_cycles_:=2,
--    boundary_:= t.geom,
--    buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 



--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='city', 
--    target_geom_:='geom',
--    source_table_:='combined_streets',
--    source_column_:='city', 
--    source_geom_:='geom',
--    tolerance_:=52,
--    angle_:=10,
--    angle_buffer_:= 12,
--    source_filter_:='city is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.7,
--    max_fill_gap_cycles_:=2,
--    boundary_:= t.geom,
--    buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t
--; 

--need to use tdg_conflate to update combined_streets with berkeley  funccional class from berkeley_centerlins
--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='funcclass',
    --target_geom_:='geom',
    --buffer_geom_:= 'conflation_buffer',
    --source_table_:='berkeley_street_centerline',
    --source_column_:='str_cat', --west/south bound bike lane buffer width
    --source_geom_:='geom',
    --tolerance_:=50,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='str_cat is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.8,
    --boundary_:= t.geom,
    --max_fill_gap_cycles_:=2

 
--)
--from grid_3mi t
--where obj_id in ('1', '2', '3', '18', '19', '20'); 


---update comprehensive_data with data from combined_bike


--facility type
--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='en_exist_bike',  --e/n facility type
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='en_exist_bike', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='en_exist_bike is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
    --buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 


--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='ws_exist_bike', --ws facility type
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='ws_exist_bike', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='ws_exist_bike is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
    --buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 




--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='ws_rec_bike', --ws facility type
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='ws_rec_bike', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='ws_rec_bike is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
    --buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 

--Select tdg_conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='en_rec_bike'
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='en_rec_bike', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='en_rec_bike is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
    --buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 


--facility width

--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='ws_bike_width', --ws facility width
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='ws_bike_width', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='ws_bike_width >0 and ws_bike_width is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
    --buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 

--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='en_bike_width', --en facility width
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='en_bike_width', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='en_bike_width >0 and en_bike_width is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
   -- buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 


--bike buffer width

--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='ws_bike_buf', --ws buf width
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='ws_bike_buf', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='ws_bike_buf >0 and ws_bike_buf is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
    --buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 

--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='en_bike_buf', --en buf width
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='en_bike_buf', 
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='en_bike_buf >0 and en_bike_buf is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
    --buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 



--udpate parking left and right

--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='parking_l', --update parking_l column
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='parking_l', --this is parking width
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='parking_l >0 and parking_l is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
  --  buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 

--SELECT tdg_Conflate(
    --target_table_:='comprehensive_data',
    --target_column_:='parking_r', --update parking_r column
    --target_geom_:='geom',
    --source_table_:='combined_bike',
    --source_column_:='parking_r', --this is parking width for east/north
    --source_geom_:='geom',
    --tolerance_:=52,
    --angle_:=10,
    --angle_buffer_:= 12,
    --source_filter_:='parking_r >0 and parking_r is not null',    -- where clause to filter the source data, if desired: NA for bike infra
    --min_target_length_:=50,
    --min_shared_length_pct_:=0.7,
    --max_fill_gap_cycles_:=2,
    --boundary_:= t.geom,
  --  buffer_geom_:='conflation_buffer'
 
--)
--from grid_3mi t; 


--need to updated oakland bike recs separately since from separated shapefile from existing bike infrastructure
--add recommended bike facilities for oakland by using tdg_conflate
---this is already done
--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='en_rec_bike',
--    target_geom_:='geom',
--    source_table_:='okland_rec_bike',
--    source_column_:='proposedcl',
--    source_geom_:='geom',
--    tolerance_:=3,
--    angle_:=30,
--    angle_buffer_:= 2,
--    source_filter_:='wbsbclassi is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=8
 
--)

	

--SELECT tdg_Conflate(
--    target_table_:='comprehensive_data',
--    target_column_:='ws_rec_bike',
--    target_geom_:='geom',
--    source_table_:='okland_rec_bike',
--    source_column_:='proposedcl',
--    source_geom_:='geom',
--    tolerance_:=3,
--    angle_:=10,
--    angle_buffer_:= 10,
--    source_filter_:='wbsbclassi is not null',    -- where clause to filter the source data, if desired: NA for bike infra
--    min_target_length_:=50,
--    min_shared_length_pct_:=0.8,
--    max_fill_gap_cycles_:=8,
--    boundary_:=t.geom
--)
--From grid t; 


-------------------------------------------------------

---cleaning combined_streets and combined_bike
--**this code needs to update compehensive_data NOT combined_streets /combined_bikes

-------------------------------------------------------
--make columns lowercase 
update combined_streets
set funcclass = lower(funcclass);

update combined_streets
set city = lower(city);

update combined_bike
 set en_exist_bike = lower(en_exist_bike);
 
update combined_bike
 set ws_exist_bike = lower(ws_exist_bike);

 update combined_bike
 set ws_rec_bike = lower(ws_rec_bike);

  update combined_bike
 set en_rec_bike = lower(en_rec_bike);





--update existing bike
update combined_bike
set en_exist_bike = CASE WHEN en_exist_bike like '%2%' or en_exist_bike like '%II%' then '2'
		    CASE WHEN en_exist_bike like '%1%' or en_exist_bike like '%I%' then '1'
		    CASE WHEN en_exist_bike like '%3%' or en_exist_bike like '%III%' then '3'
		    CASE WHEN en_exist_bike like '%4%' or en_exist_bike like '%IV%' then '4'
		    Else NULL
		    END;
update combined_bike
set ws_exist_bike = CASE WHEN ws_exist_bike like '%2%' or ws_exist_bike like '%II%' then '2'
		    CASE WHEN ws_exist_bike like '%1%' or ws_exist_bike like '%I%' then '1'
		    CASE WHEN ws_exist_bike like '%3%' or ws_exist_bike like '%III%' then '3'
		    CASE WHEN ws_exist_bike like '%4%' or ws_exist_bike like '%IV%' then '4'
		    Else NULL
		    END;

update combined_bike
set ws_rec_bike = CASE WHEN ws_rec_bike like '%2%' or ws_rec_bike like '%II%' then '2'
		    CASE WHEN ws_rec_bike like '%1%' or ws_rec_bike like '%I%' then '1'
		    CASE WHEN ws_rec_bike like '%3%' or ws_rec_bike like '%III%' then '3'
		    CASE WHEN ws_rec_bike like '%4%' or ws_rec_bike like '%IV%' then '4'
		    Else NULL
		    END;













---------------------
--python notes from looking over Bloomington:

--1.  will need to make bike lane width = bike lane + buffer where buffers exist
--2. need to include parking presence and parking width, and have assumptions for each
--3. need to think about good adt assumptions for primary/secondary/tertiary etc
--4. I think I'm confused about the centerline- if we do not have this column in  our dataset, do I need to put it in python scip? 






