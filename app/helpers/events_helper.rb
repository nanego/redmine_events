module EventsHelper

  include IssuesHelper

  def common_header(doc, title)
    <<HEADER
      <br />
      <div style="text-align: center;margin-top:10px;">
        <table border="1" cellpadding="0" cellspacing="0" id="flash_header" style="border: 2px solid rgb(0, 0, 0); box-shadow: rgb(101, 101, 101) 1px 1px 1px 0px; height: 200px; margin: 10px auto auto; text-align: center; width: 98%;">
          <tbody>
            <tr>
              <td>#{Setting['plugin_redmine_events']['logo_ministere']}<br/>
              <span style="text-align: center; font-family: arial, helvetica, sans-serif;"><strong>Ministère de l'Écologie, du Développement durable et de l'Énergie<br />
              Ministère du Logement, de l'Égalité des territoires et de la Ruralité<br />
              Service de Défense, de Sécurité et d'Intelligence Économique<br />
              <br />
              <span style="font-size: 18px;">#{title}</span></strong><br />
              du #{ I18n.l doc.start_date, format: :complete } au #{ I18n.l doc.due_date, format: :complete }</span></td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
HEADER
  end

  def bulletin_header(bulletin)
    common_header(bulletin, "BULLETIN  QUOTIDIEN  CMVOA N° #{bulletin.id}")
  end

  def point_header(point)
    common_header(point, "POINT DE SITUATION N° #{point.id}")
  end

  def bulletin_main_facts(event, related_evts)

    major_events = {}
    related_evts.each do |evt|
      domaine=evt.custom_field_value(CustomField.find_by_name('Domaines')).first
      major_events[domaine] ||= {}
      commune = evt.custom_field_value(CustomField.find_by_name('Commune'))
      major_events[domaine][commune] ||= []
      major_events[domaine][commune] << evt
    end

    main_facts = <<FAITS_MARQUANTS
      <table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(220, 220, 220);">
        <tbody>
          <tr>
            <td><strong><em><span style="font-size:18px;"> SITUATION GENERALE - PREVISIONS</span></em></strong></td>
          </tr>
        </tbody>
      </table>
FAITS_MARQUANTS

=begin
    <strong>Météorologie et crues</strong><br />
                            <div style="text-align: center;"><img src="http://www.meteofrance.com/integration/sim-portail/generated/integration/img/vigilance/mn.gif" alt="carte vigilance meteo"/><br />
        <a href="http://france.meteofrance.com/vigilance/Accueil">http://france.meteofrance.com/vigilance/Accueil</a></div>
        <br />
=end

    main_facts << <<FAITS_MARQUANTS_RESUMES_BEGIN
    <div style="text-align: left;"> 
    <table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
    <tbody>
    <tr>
    <td>
      <strong>Faits marquants</strong>
FAITS_MARQUANTS_RESUMES_BEGIN

    major_events.each do |domaine, communes|
      # main_facts << "\n## #{domaine}"
      communes.each do |commune, events|
        events.each do |event|
          resume = event.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['summary_field']))
          if resume.present? && event.priority_id >= 3
            main_facts << <<LIST_FAITS_MARQUANTS
  <ul>
	  <li>#{event.custom_field_value(CustomField.find(11)).present? ? (event.custom_field_value(CustomField.find(11)) + ( Commune.find_by_name(event.custom_field_value(CustomField.find(11))).present? ? ' (' + Commune.find_by_name(event.custom_field_value(CustomField.find(11))).department.to_s.rjust(2, '0') + ')' : '') )  : event.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['department_field']))} : #{resume}</li>
    </ul>
LIST_FAITS_MARQUANTS
          end
        end
      end
    end

    main_facts << <<FAITS_MARQUANTS_RESUMES_END
			</td>
    </tr>
	</tbody>
    </table>
</div>
FAITS_MARQUANTS_RESUMES_END

    return main_facts

  end

  def bulletin_incidents(event, related_evts)
    incidents = <<INCIDENTS
<table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(220, 220, 220);">
	<tbody>
		<tr>
			<td><strong><em><span style="font-size: 18px;"> PERTURBATIONS, INCIDENTS, ACCIDENTS </span></em></strong></td>
		</tr>
	</tbody>
</table>
<br/>
INCIDENTS

    events = {}
    related_evts.each do |evt|
      evt.custom_field_value(CustomField.find_by_name('Domaines')).each do |domaine|
        events[domaine] ||= {}
        commune = evt.custom_field_value(CustomField.find_by_name('Commune'))
        events[domaine][commune] ||= []
        events[domaine][commune] << evt
      end
    end

    events.each do |domaine, communes|
      incidents << <<DOMAINES
<table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(240, 240, 240);">
	<tbody>
		<tr>
			<td><strong><span style="font-size:16px;"> #{domaine}</span></strong></td>
		</tr>
	</tbody>
</table>
<BR/>
DOMAINES


      incidents << <<TYPES_START
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
	<tbody>
		<tr>
			<td>
TYPES_START

      communes.each do |commune, events|
        incidents << "<strong>#{commune} #{  Commune.find_by_name(commune).present? ? ' (' + Commune.find_by_name(commune).department.to_s.rjust(2, '0') + ')' : ''} :</strong>" if commune.present?
        incidents << "<ul>"
        events.each do |event|
          resume = event.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['summary_field']))

          if (event.custom_field_value(CustomField.find(16)).present? || event.custom_field_value(CustomField.find(4)).present?)

            incidents << <<TYPES_CONTENT

            <strong><span style="background-color:#FFD700;">Incident #{event.custom_field_value(CustomField.find(2))}</span><br /></strong>

            #{event.custom_field_value(CustomField.find(16)).present? ? event.custom_field_value(CustomField.find(16)) : event.custom_field_value(CustomField.find(4))}<br/>
            #{event.custom_field_value(CustomField.find(7)).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_red.png\' /><span style="padding-left: .6em;">'+event.custom_field_value(CustomField.find(7)).to_s+' morts.</span><br/>').html_safe : ''}
            #{event.custom_field_value(CustomField.find(6)).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\'/><span style="padding-left: .6em;">'+event.custom_field_value(CustomField.find(6)).to_s+' blessés.</span><br/>').html_safe : ''}
            #{event.custom_field_value(CustomField.find(17))}

TYPES_CONTENT

          end

        end
        incidents << "</ul>"
      end

      incidents << <<TYPES_STOP
			</td>
		</tr>
	</tbody>
</table>
TYPES_STOP

    end

    return incidents
  end

  def bulletin_exercices
    return <<EXERCICES
<table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(220, 220, 220);">
	<tbody>
		<tr>
			<td><strong><em><span style="font-size: 18px;"> EXERCICES (tous domaines) </span></em></strong></td>
		</tr>
	</tbody>
</table>
<br/>
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
	<tbody>
		<tr>
			<td>
        <img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_grey.png\'/> RAS<span style="padding-left: 1.0em;"></span><br/><br/>
			</td>
		</tr>
	</tbody>
</table>
EXERCICES
  end


end
