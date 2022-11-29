materialFilters = angular.module "materialFilters", ['dateHelper']

# Filters agenda and action points from meeting materials
materialFilters.filter "filterMaterials", ->
  (materials) ->
    return unless materials

    _.filter(materials, (material) -> material.material_class != 'other')


# Filters other materials than agenda and action points from meeting materials
materialFilters.filter "filterAttachments", ->
  (materials) ->
    return unless materials

    _.filter(materials, (material) -> material.material_class == 'other')
