/*
 Navicat Premium Data Transfer

 Source Server         : Local
 Source Server Type    : PostgreSQL
 Source Server Version : 90404
 Source Host           : localhost
 Source Database       : blender
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 90404
 File Encoding         : utf-8

 Date: 02/22/2016 22:52:53 PM
*/

-- ----------------------------
--  Function structure for public.addtableattr(varchar, varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."addtableattr"(varchar, varchar);
CREATE FUNCTION "public"."addtableattr"(IN varchar, IN varchar) RETURNS "bool" 
	AS $BODY$
        DECLARE
				
        BEGIN
		
	IF NOT EXISTS (SELECT $2 
               FROM information_schema.columns 
               WHERE table_schema='public' and table_name=$1 and column_name=$2) THEN
		EXECUTE 'ALTER TABLE "' || $1 || '" ADD COLUMN "' || $2 || '" character varying';
	END IF;
	
	RETURN TRUE;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."addtableattr"(IN varchar, IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.getnodeattributes(xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getnodeattributes"(xml);
CREATE FUNCTION "public"."getnodeattributes"(IN xml)
 RETURNS TABLE("key" varchar, val varchar) AS
$BODY$
        DECLARE
		rec record;
		tableName varchar;
        BEGIN			

	RETURN QUERY select (regexp_split_to_array(regexp_replace(attr, '("|'')', '', 'g'), '='))[1]::varchar as key,  (regexp_split_to_array(regexp_replace(attr, '("|'')', '', 'g'), '='))[2]::varchar as val  from
(
select unnest(regexp_matches(parentNode,'((\w|\w-\w)*\s*=\s*"[^"]*"|''[^'']*'')','g')) attr, c as val from (
SELECT unnest(xpath('@*', $1))::varchar as c, (regexp_matches($1::varchar, '(<.*?>)'::varchar))[1] as parentNode  ) x) v
where attr like '%' || v.val || '%' and attr not like 'xmlns%';
	
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	ROWS 1000
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."getnodeattributes"(IN xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.createtablenode(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."createtablenode"(varchar);
CREATE FUNCTION "public"."createtablenode"(IN varchar) RETURNS "bool" 
	AS $BODY$
        DECLARE
		
        BEGIN		
	
	IF NOT EXISTS (
		SELECT *
		FROM pg_catalog.pg_tables 
		WHERE tablename  = $1
	) THEN
		EXECUTE 'CREATE TABLE "' || $1 || '"()';
	END IF;		
	
	RETURN TRUE;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."createtablenode"(IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.decodeentities(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."decodeentities"(varchar);
CREATE FUNCTION "public"."decodeentities"(IN html varchar) RETURNS "varchar" 
	AS $BODY$
BEGIN
  RETURN REPLACE(
	REPLACE(
		REPLACE(
			REPLACE(html,'&amp;','&')
		,'&nbsp;',' ')
	, '&gt;','>')
	, '&lt;', '<');
END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	STABLE;
ALTER FUNCTION "public"."decodeentities"(IN html varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.getnodechildnames(xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getnodechildnames"(xml);
CREATE FUNCTION "public"."getnodechildnames"(IN xml) RETURNS "_varchar" 
	AS $BODY$
        DECLARE
                pParsed         varchar[];
                node         	ALIAS FOR $1;
        BEGIN		

		select array(
		SELECT DISTINCT (xpath('name()', child))[1]::varchar as attr FROM (
		SELECT unnest(xpath('./child::node()[not(text()[normalize-space()]) and name() and not(name()="value") and (node() or @*)]', node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as "child") x
WHERE 
		length(trim(regexp_replace(child::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0
) into pParsed;
/* 
		
*/
		return pParsed;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."getnodechildnames"(IN xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.getnodeattributenames(xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getnodeattributenames"(xml);
CREATE FUNCTION "public"."getnodeattributenames"(IN xml) RETURNS "_varchar" 
	AS $BODY$
        DECLARE
                pParsed         varchar[];
                node         	ALIAS FOR $1;		
        BEGIN		

		select array(
		SELECT DISTINCT (xpath('name()', child))[1]::varchar as attr FROM (
		SELECT unnest(xpath('./child::node()[text()[normalize-space()]]', node)) as "child") x
WHERE 
		length(trim(regexp_replace(child::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0
) into pParsed;
/* 
		
*/
		return pParsed;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."getnodeattributenames"(IN xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.getuniquenodeattributes(_xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."getuniquenodeattributes"(_xml);
CREATE FUNCTION "public"."getuniquenodeattributes"(IN _xml)
 RETURNS TABLE("attribute" varchar) AS
$BODY$
        DECLARE
		rec record;
		tableName varchar;
        BEGIN			

	select (xpath('name()', $1[1], '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar into tableName;

	RETURN QUERY select distinct attributes[1] as attribute from (select 
		regexp_split_to_array(
		replace(
		(regexp_matches(replace((regexp_matches($1::varchar,'(<' || tableName || '\s.*?>)','g'))[1], '\"','"')
		,'((\w|\w-\w)*\s*=\s*"[^"]*"|''[^'']*'')','g'))[1]::varchar
		,'"','')
		,'=')::varchar[] as attributes
		) x where attributes[1] <> 'xmlns' and attributes[1] <> 'lang';
	
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	ROWS 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	STABLE;
ALTER FUNCTION "public"."getuniquenodeattributes"(IN _xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.emptytable(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."emptytable"(varchar);
CREATE FUNCTION "public"."emptytable"(IN varchar) RETURNS "bool" 
	AS $BODY$
        DECLARE
		
        BEGIN		
	
	IF EXISTS (
		SELECT *
		FROM pg_catalog.pg_tables 
		WHERE tablename  = $1
	) THEN
		EXECUTE 'DELETE FROM "' || $1 || '"';
	END IF;		
	
	RETURN TRUE;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."emptytable"(IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.importcatalog(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."importcatalog"(varchar);
CREATE FUNCTION "public"."importcatalog"(IN varchar) RETURNS "bool" 
	AS $BODY$
        DECLARE
		rec record;
		tableName varchar;
        BEGIN		

	CREATE TEMP TABLE _keyval (key character varying, val character varying, lang character varying) ON COMMIT DROP;

	CREATE TEMP TABLE catalog ON COMMIT DROP AS 
		WITH cat AS (
		SELECT unnest(xpath('//n:catalog', pg_read_file($1, 0, 500000000)::xml, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) AS c
		) SELECT * FROM cat;

	CREATE TEMP TABLE nodenames on COMMIT DROP AS SELECT DISTINCT (xpath('name()', c))[1]::varchar as tableName FROM (Select unnest(xpath('//n:catalog/node()', c, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as c from catalog) ca WHERE length(trim(regexp_replace(c::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0;
		
	perform emptytable('product');
	perform emptytable('custom-attributes');
	perform emptytable('image');
	perform emptytable('variant');
	perform emptytable('variation-attribute-value');
	perform emptytable('page-attributes');

	FOR rec IN SELECT * FROM nodenames
	LOOP
		
		

		IF rec.tableName = 'product' THEN			

			FOR rec IN SELECT c as node FROM (Select unnest(xpath('//n:catalog/n:product', c, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as c from catalog) ca WHERE length(trim(regexp_replace(c::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0
			LOOP

				perform importXmlNode ( rec.node, null); --, ARRAY[['product-id', (xpath('/n:product/@product-id', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar ]] );	
				

				 
			END LOOP;
		END IF;

	END LOOP;




	
	RETURN TRUE;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."importcatalog"(IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.importimagegroupnode(xml, _varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."importimagegroupnode"(xml, _varchar);
CREATE FUNCTION "public"."importimagegroupnode"(IN xml, IN _varchar) RETURNS "bool" 
	AS $BODY$DECLARE

BEGIN

select * from image;


	RETURN true;
END;$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."importimagegroupnode"(IN xml, IN _varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for public.importxmlnode(xml, _varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."importxmlnode"(xml, _varchar);
CREATE FUNCTION "public"."importxmlnode"(IN xml, IN _varchar) RETURNS "bool" 
	AS $BODY$
        DECLARE
		skiptables varchar[];
		rec record;
		tableName varchar;
		attrName varchar;
		cols varchar;
		vals varchar;
		xlang varchar;
		attrList varchar[][];
		keyList varchar[];
		childKeyList varchar[];
		childTableName varchar;
		textval varchar;
		childNodes xml[];
		variationValue varchar;
        BEGIN			--
	
	skiptables := ARRAY['custom-attribute','images', 'image-group', 'variation-attribute', 'variation-attribute-values', 'variations', 'attributes', 'alt', 'variants'];

	DELETE FROM "_keyval";
	SELECT (xpath('name()', $1))[1]::varchar INTO tableName;
	SELECT $2 into attrList;

	if NOT(tableName = ANY(skiptables::varchar[])) then
		perform createTableNode ( tableName );

		SELECT ARRAY(SELECT getuniquenodeattributes(xpath('.',$1)) as attr) into keyList;

		FOR rec IN SELECT UNNEST(keyList) as attr
		LOOP			
			attrList := attrList || ARRAY[[rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar]];
			if(tableName = 'variant' and rec.attr = 'product-id') then
				perform addtableattr ( tableName, 'variant-product-id' );
				INSERT INTO "_keyval" (key, val) VALUES ('variant-product-id', (xpath('/n:' || tableName || '/@product-id', $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar);
				keyList := array_append(keyList, 'variant-product-id');
			else
				perform addtableattr ( tableName, rec.attr );
				INSERT INTO "_keyval" (key, val) VALUES (rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar);
			end if;
		END LOOP;

		IF $2 is not null THEN
			FOR i IN array_lower($2, 1) .. array_upper($2, 1)
			LOOP
				perform addtableattr ( tableName, $2[i][1] );
				INSERT INTO "_keyval" (key, val) VALUES ($2[i][1], $2[i][2]);	
			END LOOP;
		END IF;

	-- and (not(@xml:lang) or @xml:lang="x-default") 
		FOR rec IN select node from (select unnest (xpath('/n:' || tableName || '/child::node()[(./n:value/text() or text()[normalize-space()]) and not(@site-id)]', $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as node) n WHERE length(trim(regexp_replace(node::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0
		LOOP	
			
			IF (xpath('name()', rec.node))[1]::varchar = 'custom-attribute' THEN
				SELECT (xpath('@attribute-id', rec.node))[1]::varchar into attrName;
			ELSE
				SELECT (xpath('name()', rec.node))[1]::varchar into attrName;
			END IF;
			perform addtableattr ( tableName, attrName );			


			textVal := null;
			Select arrayVal into textVal from (SELECT array(select unnest(xpath('./n:value/text()', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))::varchar) arrayVal) x where array_length(arrayVal,1) > 0;	
			if textVal is null then
				SELECT (xpath('text()', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar into textval;
			end if;

			xlang := null;
			SELECT (xpath('@xml:lang', rec.node))[1]::varchar into xlang;
			IF xlang is null THEN
				xlang := 'x-default';
			END IF;

			INSERT INTO "_keyval" (key, val,lang) VALUES (attrName, decodeentities(textval::varchar), xlang);

		END LOOP;


		perform addtableattr ( tableName, 'x-lang' );

		
		FOR rec in SELECT DISTINCT lang FROM "_keyval" where lang is not null
		LOOP	
			
			xlang := rec.lang;

			select string_agg('"' || key::varchar || '"', ', ') into cols FROM "_keyval" where key is not null and (lang = xlang or lang is null);
			select string_agg('''' || replace(val::varchar, '''', '''''') || '''', ', ') into vals FROM "_keyval" where key is not null and (lang = xlang or lang is null);

			/*FOR rec IN SELECT UNNEST(keyList) as attr
			LOOP
				SELECT cols || ', "' || rec.attr || '"'  into cols;
				IF(rec.attr = 'variant-product-id') THEN
					SELECT vals || ', ''' || replace((xpath('./@product-id', $1))[1]::varchar,'''','''''') || ''''  into vals;
				ELSE
					SELECT vals || ', ''' || replace((xpath('./@' || rec.attr, $1))[1]::varchar,'''','''''') || ''''  into vals;
				END IF;
			END LOOP;*/

			execute 'INSERT INTO "' || tableName || '" (' || cols || ', "x-lang") VALUES (' || vals || ', ''' || xlang || ''');';
			--insert into data(text) values( 'INSERT INTO "' || tableName || '" (' || cols || ', "x-lang") VALUES (' || vals || ', ''' || xlang || ''');');
		END LOOP;
		
		--insert into "_keyval" (key) values (cols);
	ELSE	
		SELECT ARRAY(SELECT getuniquenodeattributes(xpath('.',$1)) as attr) into keyList;

		FOR rec IN SELECT UNNEST(keyList) as attr
		LOOP
			attrList := attrList || ARRAY[[rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar]];
		END LOOP;
	END IF;

	IF tableName = 'image-group' THEN
		SELECT ARRAY(SELECT getuniquenodeattributes(xpath('/n:image-group/n:variation',$1,'{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as attr) into keyList;

		FOR rec IN SELECT UNNEST(keyList) as attr
		LOOP
			variationValue = (xpath('/n:image-group/n:variation/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar;
			IF variationvalue is not null THEN
				attrList := attrList || ARRAY[[('variation-' || rec.attr)::varchar, variationValue]];
			END IF;
		END LOOP;
		
		childNodes := xpath('/n:image-group/n:image', $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}');
		FOR i IN array_lower(childNodes, 1) .. array_upper(childNodes, 1)
		LOOP
			perform importxmlnode(childNodes[i], attrList);
		END LOOP;
	ELSE
		FOR rec IN select unnest(getnodechildnames($1)) as node
		LOOP		
			childNodes := xpath('/n:' || tableName || '/n:' || rec.node, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}');
			FOR i IN array_lower(childNodes, 1) .. array_upper(childNodes, 1)
			LOOP
				perform importxmlnode(childNodes[i], attrList);
			END LOOP;
		END LOOP;
	END IF;

	
	
	RETURN TRUE;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "public"."importxmlnode"(IN xml, IN _varchar) OWNER TO "ryanrife";

