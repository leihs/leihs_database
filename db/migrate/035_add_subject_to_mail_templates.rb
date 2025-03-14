class AddSubjectToMailTemplates < ActiveRecord::Migration[7.2]
  SUBJECTS = [
    ['received', { 'en-GB' => '[leihs] Order received',
                   'en-US' => '[leihs] Order received',
                   'de-CH' => '[leihs] Bestellung eingetroffen',
                   'es' => '[leihs] Orden recibida',
                   'fr-CH' => '[leihs] Commande reçue',
                   'gsw-CH' => '[leihs] Bschtelig aachoo' }],

    ['reminder', { 'en-GB' => '[leihs] Reminder',
                   'en-US' => '[leihs] Reminder',
                   'de-CH' => '[leihs] Erinnerung',
                   'es' => '[leihs] Recordatorio',
                   'fr-CH' => '[leihs] Rappel',
                   'gsw-CH' => '[leihs] Erinnerig' }],

    ['approved', { 'en-GB' => '[leihs] Reservation Confirmation',
                   'en-US' => '[leihs] Reservation Confirmation',
                   'de-CH' => '[leihs] Reservationsbestätigung',
                   'es' => '[leihs] Reserva Confirmada',
                   'fr-CH' => '[leihs] Confirmation de réservation',
                   'gsw-CH' => '[leihs] Reservationsbeschtätigung' }],

    ['rejected', { 'en-GB' => '[leihs] Reservation Rejected',
                   'en-US' => '[leihs] Reservation Rejected',
                   'de-CH' => '[leihs] Reservation abgelehnt',
                   'es' => '[leihs] Reserva Rechazada',
                   'fr-CH' => '[leihs] Réservation refusée',
                   'gsw-CH' => '[leihs] Reservation abglehnt' }],

    ['submitted', { 'en-GB' => '[leihs] Reservation Submitted',
                    'en-US' => '[leihs] Reservation Submitted',
                    'de-CH' => '[leihs] Reservation abgeschickt',
                    'es' => '[leihs] Reserva Presentada',
                    'fr-CH' => '[leihs] Réservation envoyée',
                    'gsw-CH' => '[leihs] Reservation abgschickt' }],

    ['deadline_soon_reminder', { 'en-GB' => '[leihs] Some items should be returned tomorrow',
                                 'en-US' => '[leihs] Some items should be returned tomorrow',
                                 'de-CH' => '[leihs] Einige Gegenstände sollten morgen zurückgebracht werden',
                                 'es' => '[leihs] Algunos elementos deberían de ser devueltos mañana',
                                 'fr-CH' => '[leihs] Des éléments doivent être retourné demain',
                                 'gsw-CH' => '[leihs] Einige Sache sötted morn zruggbracht werde' }],
  ]

  def up
    add_column :mail_templates, :subject, :text

    SUBJECTS.each do |name, subjects|
      subjects.each do |locale, subject|
        execute <<~SQL
          UPDATE mail_templates
          SET subject = '#{subject}'
          WHERE name = '#{name}' AND language_locale = '#{locale}';
        SQL
      end
    end

    execute <<~SQL
      CREATE OR REPLACE FUNCTION public.insert_mail_templates_for_new_inventory_pool_f()
        RETURNS trigger
        LANGUAGE plpgsql
      AS $function$
      BEGIN
        INSERT INTO mail_templates (
          inventory_pool_id,
          name,
          format,
          subject,
          body,
          is_template_template,
          "type",
          language_locale
        )
        SELECT
          NEW.id,
          name,
          format,
          subject,
          body,
          FALSE,
          "type",
          language_locale
        FROM mail_templates
        WHERE is_template_template = TRUE;

        RETURN NEW;
      END;
      $function$
    SQL
  end
end
