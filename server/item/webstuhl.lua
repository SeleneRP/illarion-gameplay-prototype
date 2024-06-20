local Chat = require("std-chat-v1.chat")
local Routines = require("std-routines-v1.routines")
local Predicates = require("std-routines-v1.predicates")
local Skills = require("std-skills-v1.skills")
local Attributes = require("std-attributes-v1.attributes")
local Vitals = require("std-vitals-v1.vitals")
local Inventory = require("std-items-v1.inventory")
local ItemPredicates = require("std-items-v1.predicates")
local Drops = require("std-drops-v1.drops")
local BasePredicates = require("base.predicates")

function get_work_duration(entity_id)
    local dexterity = Attributes.get_attribute(entity_id, "illarion:dexterity");
    local tailoring  = math.min(100, Skills.get_skill(entity_id, "illarion:tailoring") * 10);
    
    return math.floor(-0.25 * (dexterity + tailoring) + 40);
end

register_tile_interaction("illarion:webstuhl", "use", function(entity_id, x, y, z)
    Routines.start_routine(entity_id, "illarion:loom", {
        sources = {Predicates.create_tile_source("illarion:webstuhl", x, y, z)}
    })
    Chat.speak_as_g(entity_id, i18n("illarion.loom.chat.begin_work"))
end)

Routines.register_routine("illarion:loom")
    .then(Predicates.sources_still_valid)
    .then(BasePredicates.isNotEncumbered("illarion.loom.encumbered_by_armor"))
    .then(BasePredicates.isFitForWork)
    .then(ItemPredicates.has_item_in_hand("illarion:scissors", "illarion.loom.requires_scissors"))
    .then(ItemPredicates.has_item("illarion:wool", 3, "illarion.loom.requires_wool"))
    .then(Tasks.wait(get_work_duration))
    .then(function(entity_id, data)
        turn_to_face(entity_id, data.x, data.y, data.z)

        if Inventory.damage_item(entity_id) then
            return "illarion.loom.scissors_broke"
        end

        if math.random(20) == 1 then
            return "illarion.loom.random_interruption"
        end

        Inventory.remove_item(entity_id, "illarion:wool", 3)
        local item = Inventory.create_item("illarion:cloth", 1)
        if not Inventory.add_item(entity_id, item) then
            Drops.drop_item(item, data.x, data.y, data.z)
            return "generic.inform.inventory_full"
        end

        Vitals.grow_hungry(entity_id, 100);
        Skills.learn_skill(entity_id, "illarion:tailoring", 2, 10)

        return Routines.SUCCESS
    end).on_abort(function(entity_id)
        Chat.speak_as_g(entity_id, i18n("generic.chat.abort_work"))
    end).on_failure(function(entity_id, error)
        if type(error) == "string" then
            Chat.inform(entity_id, i18n(error))
        end
    end)
