class FixPurposeTriggerOnTakeBack < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      DROP TRIGGER check_contracts_purpose_is_not_null_t ON contracts;
      CREATE TRIGGER check_contracts_purpose_is_not_null_t
        AFTER INSERT ON public.contracts
        FOR EACH ROW EXECUTE FUNCTION public.check_contracts_purpose_is_not_null_f();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER check_contracts_purpose_is_not_null_t ON contracts;
      CREATE TRIGGER check_contracts_purpose_is_not_null_t
        AFTER INSERT OR UPDATE ON public.contracts
        FOR EACH ROW EXECUTE FUNCTION public.check_contracts_purpose_is_not_null_f();
    SQL
  end
end
