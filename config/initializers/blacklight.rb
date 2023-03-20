Rails.application.config.to_prepare do
  Blacklight::Rendering::Pipeline.operations = [Blacklight::Rendering::HelperMethod,
                                                Blacklight::Rendering::LinkToFacet,
                                                Blacklight::Rendering::Microdata,
                                                Rendering::PreserveNewLines,
                                                Rendering::AutoLink,
                                                Rendering::CustomJoin]
end
