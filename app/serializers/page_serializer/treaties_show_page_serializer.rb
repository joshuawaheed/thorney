module PageSerializer
  class TreatiesShowPageSerializer < LaidThingShowPageSerializer
    # Initialise a Treaties show page serializer.
    #
    # @param [ActionDispatch::Request] request the current request object.
    # @param [<Grom::Node>] treaty a Grom::Node object of type Treaty.
    # @param [Array<Hash>] data_alternates array containing the href and type of the alternative data urls
    def initialize(request: nil, treaty:, data_alternates: nil)
      @treaty = treaty
      @lead_government_organisation = @treaty.try(:treatyHasLeadGovernmentOrganisation)
      @treaty_series_membership = @treaty.try(:treatyHasSeriesMembership)

      super(request: request, laid_thing: @treaty, data_alternates: data_alternates)
    end

    private

    def meta
      super(title: title)
    end

    def heading1_component
      ComponentSerializer::Heading1ComponentSerializer.new(heading_content).to_h
    end

    def title_context
      prefix  = @treaty.try(:treatyCommandPaperPrefix)
      number  = @treaty.try(:treatyCommandPaperNumber)

      ctx_info = ''
      ctx_info << prefix.to_s if prefix
      ctx_info << " #{number}" if number

      ctx_info unless ctx_info.empty?
    end

    def heading_content
      {}.tap do |hash|
        hash[:subheading] = ContentDataHelper.content_data(content: 'treaties.show.subheading', link: treaties_path)
        hash[:heading] = title || t('no_name')
        hash[:context] = title_context
      end
    end

    def meta_info
      [].tap do |items|
        web_link = @laid_thing.try(:workPackagedThingHasWorkPackagedThingWebLink)
        items << create_description_list_item(term: 'laid-thing.web-link', descriptions: [link_to(web_link, web_link)]) if web_link
        items << create_description_list_item(term: 'laid-thing.laid-date', descriptions: [TimeHelper.time_translation(date_first: @laid_thing&.laying&.date)]) if @laid_thing&.laying&.date
        items << create_description_list_item(term: 'laid-thing.laying-person', descriptions: [@laying_person&.display_name]) if @laying_person
        items << create_description_list_item(term: 'laid-thing.laying-body', descriptions: [link_to(@laying_body.try(:groupName), group_path(@laying_body.graph_id))]) if @laying_body
        items << create_description_list_item(term: 'laid-thing.lead-government-organisation', descriptions: connected_lead_government_organisation)
        items << create_description_list_item(term: 'series-membership.series-item-citation', descriptions: treaty_series_membership_citations)
      end.compact
    end

    def connected_lead_government_organisation
      @lead_government_organisation.map do |government_organisation|
        link_to(government_organisation.try(:groupName), group_path(government_organisation.graph_id))
      end
    end

    def treaty_series_membership_citations
      @treaty_series_membership.map do |series_membership|
        series_membership.try(:seriesItemCitation)
      end
    end
  end
end
