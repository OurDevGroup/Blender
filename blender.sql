CREATE SCHEMA IF NOT EXISTS blender;

-- ----------------------------
--  Function structure for blender.settablecolumndatatype(_varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."settablecolumndatatype"(_varchar);
CREATE FUNCTION "blender"."settablecolumndatatype"(IN _varchar) RETURNS "bool" 
	AS $BODY$DECLARE
	tableList ALIAS for $1;
	rec record;
BEGIN
	FOR i IN array_lower(tableList, 1) .. array_upper(tableList, 1)
	LOOP

		FOR rec IN SELECT * FROM information_schema.columns WHERE table_schema='blender' and table_name=tableList[i]
		LOOP
			IF rec.data_type='character varying' THEN
				IF (SELECT iscolumndate(rec.table_name, rec.column_name)) THEN
					EXECUTE 'ALTER TABLE "' || rec.table_name || '" ALTER COLUMN "' || rec.column_name || '" TYPE timestamp USING "' || rec.column_name || '"::timestamp';
				ELSEIF (SELECT iscolumnbool(rec.table_name, rec.column_name)) THEN
					EXECUTE 'ALTER TABLE "' || rec.table_name || '" ALTER COLUMN "' || rec.column_name || '" TYPE bool USING "' || rec.column_name || '"::bool';
				END IF;
			END IF;
		END LOOP;

	END LOOP;


	RETURN true;
END;$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "blender"."settablecolumndatatype"(IN _varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.iscolumnbool(varchar, varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."iscolumnbool"(varchar, varchar);
CREATE FUNCTION "blender"."iscolumnbool"(IN varchar, IN varchar) RETURNS "bool" 
	AS $BODY$DECLARE
	tableName ALIAS FOR $1;	
	columnName ALIAS FOR $2;	
	returnVal bool;
BEGIN
	EXECUTE 'select (select count("' || columnName || '") from "' || tableName || '" where "' || columnName || '" is not null and "' || columnName || '" ~ E''^(true|false)$'') = (select count("' || columnName || '") from "' || tableName || '" where "' || columnName || '" is not null)' INTO returnVal;
	RETURN returnVal;
END;$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	STABLE;
ALTER FUNCTION "blender"."iscolumnbool"(IN varchar, IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.getnodeattributes(xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."getnodeattributes"(xml);
CREATE FUNCTION "blender"."getnodeattributes"(IN xml)
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
ALTER FUNCTION "blender"."getnodeattributes"(IN xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.decodeentities(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."decodeentities"(varchar);
CREATE FUNCTION "blender"."decodeentities"(IN html varchar) RETURNS "varchar" 
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
ALTER FUNCTION "blender"."decodeentities"(IN html varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.getnodechildnames(xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."getnodechildnames"(xml);
CREATE FUNCTION "blender"."getnodechildnames"(IN xml) RETURNS "_varchar" 
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
ALTER FUNCTION "blender"."getnodechildnames"(IN xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.getnodeattributenames(xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."getnodeattributenames"(xml);
CREATE FUNCTION "blender"."getnodeattributenames"(IN xml) RETURNS "_varchar" 
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
ALTER FUNCTION "blender"."getnodeattributenames"(IN xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.getuniquenodeattributes(_xml)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."getuniquenodeattributes"(_xml);
CREATE FUNCTION "blender"."getuniquenodeattributes"(IN _xml)
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
ALTER FUNCTION "blender"."getuniquenodeattributes"(IN _xml) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.emptytable(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."emptytable"(varchar);
CREATE FUNCTION "blender"."emptytable"(IN varchar) RETURNS "bool" 
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
ALTER FUNCTION "blender"."emptytable"(IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.importimagegroupnode(xml, _varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."importimagegroupnode"(xml, _varchar);
CREATE FUNCTION "blender"."importimagegroupnode"(IN xml, IN _varchar) RETURNS "bool" 
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
ALTER FUNCTION "blender"."importimagegroupnode"(IN xml, IN _varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.importcatalogxmlnode(xml, varchar, _varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."importcatalogxmlnode"(xml, varchar, _varchar);
CREATE FUNCTION "blender"."importcatalogxmlnode"(IN xml, IN varchar, IN _varchar) RETURNS "bool" 
	AS $BODY$DECLARE
	skiptables varchar[] := ARRAY['custom-attribute','images', 'image-group', 'variation-attribute', 'variation-attribute-values', 'variations', 'variation', 'attributes', 'alt', 'variants', 'refinement-definitions', 'attribute-groups'];
	parenttables varchar[] := ARRAY['product','category'];
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
	parentTable ALIAS FOR $2;
	sqlTable varchar;
	childNodes xml[];
	parentAttrList ALIAS FOR $3;
	langCount int;
BEGIN			
	
	DELETE FROM "_keyval";
	SELECT (xpath('name()', $1))[1]::varchar INTO tableName;

	IF tableName = ANY(parenttables::varchar[]) THEN
		parentTable := tableName;
		sqlTable := tableName;
	ELSE
		sqlTable := (SELECT CASE WHEN parentTable IS NULL THEN tableName ELSE parentTable || '-' || tableName END);
	END IF;	

	if NOT(tableName = ANY(skiptables::varchar[])) then

		perform createTableNode ( sqlTable );

		IF parentAttrList is not null THEN
			FOR i IN array_lower(parentAttrList, 1) .. array_upper(parentAttrList, 1)
			LOOP
				perform addtableattr ( sqlTable, parentAttrList[i][1] );
				INSERT INTO "_keyval" (key, val) VALUES (parentAttrList[i][1], parentAttrList[i][2]);	
			END LOOP;
		END IF;

		SELECT ARRAY(SELECT getuniquenodeattributes(xpath('.',$1)) as attr) into keyList;
		FOR rec IN SELECT UNNEST(keyList) as attr
		LOOP						
			if(tableName = 'variant' and rec.attr = 'product-id') then
				perform addtableattr ( sqlTable, 'variant-product-id' );
				INSERT INTO "_keyval" (key, val) VALUES ('variant-product-id', (xpath('/n:' || tableName || '/@product-id', $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar);
				parentAttrList := parentAttrList || ARRAY[['variant-product-id', (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar]];		
			else
				perform addtableattr ( sqlTable, rec.attr );
				INSERT INTO "_keyval" (key, val) VALUES (rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar);
				parentAttrList := parentAttrList || ARRAY[[rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar]];
			end if;
		END LOOP;

		FOR rec IN select node from (select unnest (xpath('/n:' || tableName || '/child::node()[(./n:value/text() or text()[normalize-space()]) and not(@site-id)]', $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as node) n WHERE length(trim(regexp_replace(node::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0
		LOOP	
			
			IF (xpath('name()', rec.node))[1]::varchar = 'custom-attribute' THEN
				SELECT (xpath('@attribute-id', rec.node))[1]::varchar into attrName;
			ELSE
				SELECT (xpath('name()', rec.node))[1]::varchar into attrName;
			END IF;
			perform addtableattr ( sqlTable, attrName );		

			xlang := null;
			SELECT (xpath('@xml:lang', rec.node))[1]::varchar into xlang;
			IF xlang is null THEN
				xlang := 'x-default';
			END IF;
			
			textVal := null;
			Select arrayVal into textVal from (SELECT array(select unnest(xpath('./n:value/text()', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))::varchar) arrayVal) x where array_length(arrayVal,1) > 0;	
			if textVal is null then
				SELECT (xpath('text()', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar into textval;
			end if;

			INSERT INTO "_keyval" (key, val,lang) VALUES (attrName, decodeentities(textval::varchar), xlang);

		END LOOP;		

		SELECT count(DISTINCT lang) into langCount FROM "_keyval" where lang is not null;

		IF langCount > 0 THEN
			perform addtableattr ( sqlTable , 'x-lang' );

			FOR rec in SELECT DISTINCT lang FROM "_keyval" where lang is not null
			LOOP					
				select rec.lang into xlang;
				select string_agg('"' || key::varchar || '"', ', ') into cols FROM "_keyval" where key is not null and (lang is null or lang = rec.lang);
				select string_agg('''' || replace(val::varchar, '''', '''''') || '''', ', ') into vals FROM "_keyval" where key is not null and (lang is null or lang = rec.lang);

				execute 'INSERT INTO "' || sqlTable || '" (' || cols || ', "x-lang") VALUES (' || vals || ', ''' || xlang || ''');';
			END LOOP;
		ELSE
			select string_agg('"' || key::varchar || '"', ', ') into cols FROM "_keyval" where key is not null;
			select string_agg('''' || replace(val::varchar, '''', '''''') || '''', ', ') into vals FROM "_keyval" where key is not null;

			execute 'INSERT INTO "' || sqlTable || '" (' || cols || ') VALUES (' || vals || ');';
		END IF;
		
	ELSE	
		SELECT ARRAY(SELECT getuniquenodeattributes(xpath('.',$1)) as attr) into keyList;

		FOR rec IN SELECT UNNEST(keyList) as attr
		LOOP
			parentAttrList := parentAttrList || ARRAY[[rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar]];
		END LOOP;
	END IF;


	FOR rec IN select unnest(getnodechildnames($1)) as node
	LOOP		
		childNodes := xpath('/n:' || tableName || '/n:' || rec.node, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}');
		FOR i IN array_lower(childNodes, 1) .. array_upper(childNodes, 1)
		LOOP		
			perform importcatalogxmlnode(childNodes[i], parentTable, parentAttrList);			
		END LOOP;
	END LOOP;
	
	RETURN TRUE;
END;$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "blender"."importcatalogxmlnode"(IN xml, IN varchar, IN _varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.addtableattr(varchar, varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."addtableattr"(varchar, varchar);
CREATE FUNCTION "blender"."addtableattr"(IN varchar, IN varchar) RETURNS "bool" 
	AS $BODY$
        DECLARE
				
        BEGIN
		
	IF NOT EXISTS (SELECT $2 
               FROM information_schema.columns 
               WHERE table_schema='blender' and table_name=$1 and column_name=$2) THEN
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
ALTER FUNCTION "blender"."addtableattr"(IN varchar, IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.createtablenode(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."createtablenode"(varchar);
CREATE FUNCTION "blender"."createtablenode"(IN varchar) RETURNS "bool" 
	AS $BODY$DECLARE
	
BEGIN		

IF NOT EXISTS (
	SELECT *
	FROM pg_catalog.pg_tables 
	WHERE tablename  = $1
) THEN
	EXECUTE 'CREATE TABLE "' || $1 || '"()';
	INSERT INTO _newtables ( tableName) VALUES ( $1 );
END IF;		

RETURN TRUE;
END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "blender"."createtablenode"(IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.importheaderxmlnode(xml, varchar, _varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."importheaderxmlnode"(xml, varchar, _varchar);
CREATE FUNCTION "blender"."importheaderxmlnode"(IN xml, IN varchar, IN _varchar) RETURNS "bool" 
	AS $BODY$DECLARE
	skiptables varchar[] := (ARRAY['view-types'])::varchar[];
	parenttables varchar[] := (ARRAY[])::varchar[];
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
	parentTable ALIAS FOR $2;
	sqlTable varchar;
	childNodes xml[];
	parentAttrList ALIAS FOR $3;
	langCount int;
BEGIN			
	
	DELETE FROM "_keyval";
	SELECT (xpath('name()', $1))[1]::varchar INTO tableName;

	IF tableName = ANY(parenttables::varchar[]) THEN
		parentTable := tableName;
		sqlTable := tableName;
	ELSE
		sqlTable := (SELECT CASE WHEN parentTable IS NULL THEN tableName ELSE parentTable || '-' || tableName END);
	END IF;	

	if NOT(tableName = ANY(skiptables::varchar[])) then

		perform createTableNode ( sqlTable );

		IF parentAttrList is not null THEN
			FOR i IN array_lower(parentAttrList, 1) .. array_upper(parentAttrList, 1)
			LOOP
				perform addtableattr ( sqlTable, parentAttrList[i][1] );
				INSERT INTO "_keyval" (key, val) VALUES (parentAttrList[i][1], parentAttrList[i][2]);	
			END LOOP;
		END IF;

		SELECT ARRAY(SELECT getuniquenodeattributes(xpath('.',$1)) as attr) into keyList;
		FOR rec IN SELECT UNNEST(keyList) as attr
		LOOP						
			perform addtableattr ( sqlTable, rec.attr );
			INSERT INTO "_keyval" (key, val) VALUES (rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar);
			parentAttrList := parentAttrList || ARRAY[[rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar]];
		END LOOP;
		
		IF tableName = 'view-type' THEN		
			perform addtableattr ( sqlTable, tableName );		

			textVal := null;
			SELECT (xpath('text()', $1))[1]::varchar into textval;
		
			INSERT INTO "_keyval" (key, val) VALUES (tableName, decodeentities(textval::varchar));
		END IF;

		FOR rec IN select node from (select unnest (xpath('/n:' || tableName || '/child::node()[(./n:value/text() or text()[normalize-space()]) and not(@site-id)]', $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as node) n WHERE length(trim(regexp_replace(node::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0
		LOOP	
			SELECT (xpath('name()', rec.node))[1]::varchar into attrName;
			perform addtableattr ( sqlTable, attrName );		

			textVal := null;
			Select arrayVal into textVal from (SELECT array(select unnest(xpath('./n:value/text()', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))::varchar) arrayVal) x where array_length(arrayVal,1) > 0;
			if textVal is null then
				SELECT (xpath('text()', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar into textval;
			end if;

			INSERT INTO "_keyval" (key, val) VALUES (attrName, decodeentities(textval::varchar));

		END LOOP;		

		select string_agg('"' || key::varchar || '"', ', ') into cols FROM "_keyval" where key is not null;
		select string_agg('''' || replace(val::varchar, '''', '''''') || '''', ', ') into vals FROM "_keyval" where key is not null;

		execute 'INSERT INTO "' || sqlTable || '" (' || cols || ') VALUES (' || vals || ');';		
	ELSE	
		SELECT ARRAY(SELECT getuniquenodeattributes(xpath('.',$1)) as attr) into keyList;

		FOR rec IN SELECT UNNEST(keyList) as attr
		LOOP
			parentAttrList := parentAttrList || ARRAY[[rec.attr, (xpath('/n:' || tableName || '/@' || rec.attr, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar]];
		END LOOP;
	END IF;

	IF tableName = 'view-types' THEN
		childNodes := xpath('/n:' || tableName || '/n:view-type', $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}');
		FOR i IN array_lower(childNodes, 1) .. array_upper(childNodes, 1)
		LOOP		
			perform importheaderxmlnode(childNodes[i], parentTable, parentAttrList);			
		END LOOP;		
	ELSE
		FOR rec IN select unnest(getnodechildnames($1)) as node
		LOOP		
			childNodes := xpath('/n:' || tableName || '/n:' || rec.node, $1, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}');
			FOR i IN array_lower(childNodes, 1) .. array_upper(childNodes, 1)
			LOOP		
				perform importheaderxmlnode(childNodes[i], parentTable, parentAttrList);			
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
ALTER FUNCTION "blender"."importheaderxmlnode"(IN xml, IN varchar, IN _varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.iscolumnnumeric(varchar, varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."iscolumnnumeric"(varchar, varchar);
CREATE FUNCTION "blender"."iscolumnnumeric"(IN varchar, IN varchar) RETURNS "bool" 
	AS $BODY$--iscolumnnumeric
DECLARE
	tableName ALIAS FOR $1;	
	columnName ALIAS FOR $2;	
	returnVal bool;
BEGIN
	EXECUTE 'select (select count("' || columnName || '") from "' || tableName || '" where "' || columnName || '" is not null and "' || columnName || '" ~ E''^\\d+$'') = (select count("' || columnName || '") from "' || tableName || '" where "' || columnName || '" is not null)' INTO returnVal;
	RETURN returnVal;
END;$BODY$
	LANGUAGE plpgsql
	COST 1000
	CALLED ON NULL INPUT
	SECURITY INVOKER
	STABLE;
ALTER FUNCTION "blender"."iscolumnnumeric"(IN varchar, IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.importcatalog(varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."importcatalog"(varchar);
CREATE FUNCTION "blender"."importcatalog"(IN varchar) RETURNS "bool" 
	AS $BODY$
        DECLARE
		rec record;
		tableName varchar;
		catalogId varchar;
        BEGIN		

	CREATE TEMP TABLE _keyval (key character varying, val character varying, lang character varying) ON COMMIT DROP;
	CREATE TEMP TABLE _newtables (tableName character varying) ON COMMIT DROP;

	CREATE TEMP TABLE _catalog ON COMMIT DROP AS 
	WITH cat AS (
		SELECT unnest(xpath('//n:catalog', pg_read_file($1, 0, 500000000)::xml, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) AS c
	) SELECT * FROM cat;

	--CREATE TEMP TABLE nodenames on COMMIT DROP AS SELECT DISTINCT (xpath('name()', c))[1]::varchar as tableName FROM (Select unnest(xpath('//n:catalog/node()', c, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) as c from _catalog) ca WHERE length(trim(regexp_replace(c::varchar, E'[\\n\\r]+', ' ', 'g' ))) > 0;
		
	SELECT (xpath('//n:catalog/@catalog-id', c, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar INTO catalogId from _catalog;

	perform emptytable('product');
	perform emptytable('product-custom-attributes');
	perform emptytable('product-image');
	perform emptytable('product-page-attributes');	
	perform emptytable('product-variant');
	perform emptytable('product-variation-attribute-value');

	perform emptytable('category');
	perform emptytable('category-assignment');
	perform emptytable('category-attribute-group');
	perform emptytable('category-custom-attributes');
	perform emptytable('category-page-attributes');
	perform emptytable('category-refinement-definition');
	
	FOR rec IN SELECT UNNEST(xpath('//n:catalog/node()[node() or text()]', c, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}')) AS node FROM _catalog
	LOOP
		tableName := (xpath('name()', rec.node))[1]::varchar;

		IF tableName <> 'header' THEN			
			perform importcatalogxmlnode ( rec.node, null, ARRAY[['catalog-id',catalogId]]); --, ARRAY[['product-id', (xpath('/n:product/@product-id', rec.node, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1]::varchar ]] );					
		ELSE
			perform emptytable('header');
			perform emptytable('header-external-location');
			perform emptytable('header-image-settings');
			perform emptytable('header-view-type');	
	
			perform importheaderxmlnode((SELECT (xpath('//n:catalog/n:header', c, '{{n, http://www.demandware.com/xml/impex/catalog/2006-10-31}}'))[1] as c from _catalog), 'catalog', ARRAY[['catalog-id',catalogId]]);
		END IF;
	END LOOP;


	FOR rec IN SELECT * FROM _newtables
	LOOP
		perform settablecolumndatatype(ARRAY[rec.tableName]);
	END LOOP;

	
	RETURN TRUE;
	END;
$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	VOLATILE;
ALTER FUNCTION "blender"."importcatalog"(IN varchar) OWNER TO "ryanrife";

-- ----------------------------
--  Function structure for blender.iscolumndate(varchar, varchar)
-- ----------------------------
DROP FUNCTION IF EXISTS "blender"."iscolumndate"(varchar, varchar);
CREATE FUNCTION "blender"."iscolumndate"(IN varchar, IN varchar) RETURNS "bool" 
	AS $BODY$DECLARE
	tableName ALIAS FOR $1;	
	columnName ALIAS FOR $2;	
	returnVal bool;
BEGIN
	EXECUTE 'select (select count("' || columnName || '") from "' || tableName || '" where "' || columnName || '" is not null and "' || columnName || '" ~ E''^(([0-9]+-[0-9]+-[0-9]+T[0-2]\\d:[0-5]\\d:[0-5]\\d\\.\\d+)|(\\d{4}-[01]\\d-[0-3]\\dT[0-2]\\d:[0-5]\\d:[0-5]\\d)|(\\d{4}-[01]\\d-[0-3]\\dT[0-2]\\d:[0-5]\\d)*.)\\w$'') = (select count("' || columnName || '") from "' || tableName || '" where "' || columnName || '" is not null)' INTO returnVal;
	RETURN returnVal;
END;$BODY$
	LANGUAGE plpgsql
	COST 100
	CALLED ON NULL INPUT
	SECURITY INVOKER
	STABLE;
ALTER FUNCTION "blender"."iscolumndate"(IN varchar, IN varchar) OWNER TO "ryanrife";

