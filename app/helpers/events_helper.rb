module EventsHelper

  include IssuesHelper

  def common_header(title, dates)
    <<HEADER
      <br />
      <div style="text-align: center;margin-top:10px;">
        <table border="1" cellpadding="0" cellspacing="0" id="flash_header" style="border: 2px solid rgb(0, 0, 0); box-shadow: rgb(101, 101, 101) 1px 1px 1px 0px; height: 200px; margin: 10px auto auto; text-align: center; width: 98%;">
          <tbody>
            <tr>
              <td>#{Setting['plugin_redmine_events']['logo_ministere']}<br/>
              <span style="text-align: center; font-family: arial, helvetica, sans-serif;"><strong>Ministère de l'Environnement, de l’Énergie et de la Mer<br />
              Ministère du Logement et de l'Habitat Durable<br />
              Service de Défense, de Sécurité et d'Intelligence Économique<br />
              <br />
              <span style="font-size: 18px;">#{title}</span></strong><br />
                #{dates}
              </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
HEADER
  end

  def bulletin_header(bulletin)
    start_date_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['start_date_field'])
    end_date_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['end_date_field'])
    common_header("BULLETIN  QUOTIDIEN  CMVOA N° #{bulletin.id}", "du #{ I18n.l(DateTime.parse(bulletin.custom_value_for(start_date_custom_field).to_s), format: :complete) } au #{ I18n.l(DateTime.parse(bulletin.custom_value_for(end_date_custom_field).to_s), format: :complete) }")
  end

  def point_header(point)
    common_header("POINT DE SITUATION N° #{point.id}", "")
  end

  def grouped_events_by_domain(events)
    departements_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['department_field'])
    grouped_events = {}
    events.each do |evt|
      domaines=evt.custom_field_value(CustomField.find_by_name('Domaines'))
      domaines.each do |domaine|
        grouped_events[domaine] ||= {}
        departments = evt.custom_field_value(departements_custom_field)
        grouped_events[domaine][departments] ||= []
        grouped_events[domaine][departments] << evt
      end
    end
    grouped_events
  end

  def bulletin_main_facts(related_evts)

    # Init data
    summary_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['summary_field'])
    events_by_domain = grouped_events_by_domain(related_evts)

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
FAITS_MARQUANTS_RESUMES_BEGIN

    events_by_domain.each do |domaine, departments|
      # main_facts << "\n## #{domaine}"
      departments.each do |department, events|
        events.each do |event|
          resume = event.custom_field_value(summary_custom_field)
          department = department.join(', ') if department.kind_of? Array
          if resume.present? && event.priority_id >= 3
            main_facts << <<LIST_FAITS_MARQUANTS
  <ul>
	  <li>#{department} : #{resume}</li>
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

  def bulletin_incidents(document, related_evts)

    show_general_information = document.tracker==Tracker.find_by_name('Bulletin de synthèse')

    summary_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['summary_field'])
    facts_custom_field = CustomField.find_by_id(16)
    category_custom_field = CustomField.find_by_id(2)
    engaged_actions_custom_field = CustomField.find_by_id(17)

    dead_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_deads_field'])
    badly_wounded_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_badly_wounded_field'])
    slightly_wounded_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_slightly_wounded_field'])
    wounded_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_wounded_field'])
    lost_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_lost_field'])

    start_date_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['start_date_field'])
    last_updated_at_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['last_updated_at_field'])

    events_by_domain = grouped_events_by_domain(related_evts)


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

    events_by_domain.each do |domaine, departments|
      incidents << titre_domaine(domaine)

      incidents << tableau_qualite_de_l_air if show_general_information && domaine.include?('Environnement')

      incidents << <<TYPES_START
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
	<tbody>
		<tr>
			<td>
TYPES_START

      departments.each do |department, events|
        department = department.join(', ') if department.kind_of? Array
        incidents << "<strong>#{department}:</strong>"
        incidents << "<ul>"
        events.each do |event|

          start_date =  DateTime.parse(event.custom_field_value(start_date_custom_field)) if event.custom_field_value(start_date_custom_field).present?
          last_updated_at =  DateTime.parse(event.custom_field_value(last_updated_at_custom_field)) if event.custom_field_value(last_updated_at_custom_field).present?
          # TODO Check if we should really use last_updated_at when start_date is empty

          if (event.custom_field_value(facts_custom_field).present? || event.custom_field_value(summary_custom_field).present?)

            incidents << <<EVENT_CONTENT

            <strong><span style="background-color:#FFD700;">Incident #{event.custom_field_value(category_custom_field)}</span><br /></strong>

            #{event.custom_field_value(facts_custom_field).present? ? event.custom_field_value(facts_custom_field) : event.custom_field_value(summary_custom_field)}
            Le #{ I18n.l((start_date || last_updated_at), format: :complete_without_year) if (start_date || last_updated_at) }
            <br/>
            #{event.custom_field_value(dead_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_red.png\' /><span style="padding-left: .6em;">'+pluralize(event.custom_field_value(dead_number_custom_field), 'mort')+(event.custom_value_for(dead_number_custom_field).comment.present? ? " (#{event.custom_value_for(dead_number_custom_field).comment})" : "" )+'</span><br/>').html_safe : ''}
            #{event.custom_field_value(lost_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\'/><span style="padding-left: .6em;">'+pluralize(event.custom_field_value(lost_number_custom_field), 'disparu')+(event.custom_value_for(lost_number_custom_field).comment.present? ? " (#{event.custom_value_for(lost_number_custom_field).comment})" : "" )+'</span><br/>').html_safe : ''}
            #{event.custom_field_value(badly_wounded_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\' /><span style="padding-left: .6em;">'+pluralize(event.custom_field_value(badly_wounded_number_custom_field), 'blessé')+' '+'grave'.pluralize(event.custom_field_value(badly_wounded_number_custom_field).to_i)+(event.custom_value_for(badly_wounded_number_custom_field).comment.present? ? " (#{event.custom_value_for(badly_wounded_number_custom_field).comment})" : "" )+'</span><br/>').html_safe : ''}
            #{event.custom_field_value(slightly_wounded_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\'/><span style="padding-left: .6em;">'+pluralize(event.custom_field_value(slightly_wounded_number_custom_field), 'blessé')+' '+'léger'.pluralize(event.custom_field_value(slightly_wounded_number_custom_field).to_i)+(event.custom_value_for(slightly_wounded_number_custom_field).comment.present? ? " (#{event.custom_value_for(slightly_wounded_number_custom_field).comment})" : "" )+'</span><br/>').html_safe : ''}
            #{event.custom_field_value(wounded_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\' /><span style="padding-left: .6em;">'+pluralize(event.custom_field_value(wounded_number_custom_field), 'blessé')+(event.custom_value_for(wounded_number_custom_field).comment.present? ? " (#{event.custom_value_for(wounded_number_custom_field).comment})" : "" )+'</span><br/>').html_safe : ''}

            #{event.custom_field_value(engaged_actions_custom_field)}

EVENT_CONTENT

            incidents << <<SOURCES
            <div style="text-align: right;"><em>#{'Source'.pluralize(event.taggings.size)} : #{event.taggings.map{|source| "#{source.tag.name}#{source.details.present? ? ' ('+source.details.to_s+')' : '' }"}.join(', ')}</em></div>
SOURCES

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

    if show_general_information
      incidents << sous_domaine_environnement unless events_by_domain.map{|domaine,value| domaine }.any?{|domaine| domaine.include?('Environnement')}
    end

    return incidents
  end

  def sous_domaine_environnement
    txt = titre_domaine('Environnement, Risques industriels')
    txt << tableau_qualite_de_l_air
    txt
  end

  def titre_domaine(domaine)
    txt = <<DOMAINES
    <table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(240, 240, 240);">
      <tbody>
        <tr>
          <td><strong><span style="font-size:16px;"> #{domaine}</span></strong></td>
        </tr>
      </tbody>
    </table>
    <BR/>
DOMAINES
    txt
  end

  def tableau_qualite_de_l_air
    <<QUALITE_DE_L_AIR
    <table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
      <tbody>
        <tr>
          <td>
          <ul>
            <li>Le Laboratoire Central de Surveillance de la Qualité de l'Air informe (base de données nationale) :</li>
          </ul>

          <table align="center" border="1" cellpadding="0" cellspacing="0" style="width:90%;">
            <tbody>
              <tr>
                <td style="text-align: center;"> </td>
                <td style="text-align: center;border:1px #000000 solid;">--date à renseigner--</td>
                <td style="text-align: center;border:1px #000000 solid;">--date à renseigner--</td>
              </tr>
              <tr>
                <td style="text-align: center;"> </td>
                <td style="text-align: center;border:1px #000000 solid;">XX régions renseignées</td>
                <td style="text-align: center;border:1px #000000 solid;">XX régions renseignées</td>
              </tr>
              <tr>
                <td style="text-align: center;border:1px #000000 solid;"><span style="color:#FF8C00;">Qualité de l'air<br />
                <strong>moyenne à médiocre</strong><br />
                (niveau 5 à 7 de l'indice ATMO)</span></td>
                <td style="text-align: center;border:1px #000000 solid;">XX agglomérations situées dans X régions</td>
                <td style="text-align: center;border:1px #000000 solid;">XX agglomérations situées dans X régions</td>
              </tr>
              <tr>
                <td style="text-align: center;border:1px #000000 solid;"><strong>Mesures préfectorales déclenchées</strong></td>
                <td style="text-align: center;border:1px #000000 solid;">Néant</td>
                <td style="text-align: center;border:1px #000000 solid;">Néant</td>
              </tr>
            </tbody>
          </table>

          <div style="text-align: center;"><a href="http://www.lcsqa.org" target="_blank">Consultation du site du LCSQA</a></div>

          <div style="text-align: right;">Sources : LCSQA, Météo France</div>
          </td>
        </tr>
      </tbody>
    </table>
QUALITE_DE_L_AIR
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
