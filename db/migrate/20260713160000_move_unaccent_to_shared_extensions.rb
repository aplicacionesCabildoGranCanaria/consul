# frozen_string_literal: true

class MoveUnaccentToSharedExtensions < ActiveRecord::Migration[7.2]
  SHARED_EXTENSIONS_SCHEMA = "shared_extensions"
  EXTENSION_NAME = "unaccent"

  def up
    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS #{SHARED_EXTENSIONS_SCHEMA};
    SQL

    execute <<~SQL
      DO $$
      DECLARE
        extension_schema text;
      BEGIN
        SELECT namespace.nspname
          INTO extension_schema
          FROM pg_extension extension
          JOIN pg_namespace namespace
            ON namespace.oid = extension.extnamespace
         WHERE extension.extname = '#{EXTENSION_NAME}';

        IF extension_schema IS NULL THEN
          CREATE EXTENSION #{EXTENSION_NAME}
            WITH SCHEMA #{SHARED_EXTENSIONS_SCHEMA};
        ELSIF extension_schema <> '#{SHARED_EXTENSIONS_SCHEMA}' THEN
          ALTER EXTENSION #{EXTENSION_NAME}
            SET SCHEMA #{SHARED_EXTENSIONS_SCHEMA};
        END IF;
      END
      $$;
    SQL
  end

  def down
    execute <<~SQL
      DO $$
      DECLARE
        extension_schema text;
      BEGIN
        SELECT namespace.nspname
          INTO extension_schema
          FROM pg_extension extension
          JOIN pg_namespace namespace
            ON namespace.oid = extension.extnamespace
         WHERE extension.extname = '#{EXTENSION_NAME}';

        IF extension_schema = '#{SHARED_EXTENSIONS_SCHEMA}' THEN
          ALTER EXTENSION #{EXTENSION_NAME}
            SET SCHEMA public;
        END IF;
      END
      $$;
    SQL

    execute <<~SQL
      DROP SCHEMA IF EXISTS #{SHARED_EXTENSIONS_SCHEMA};
    SQL
  end
end