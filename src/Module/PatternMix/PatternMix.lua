--- ======================================================================================================
---
---                                                 [ Pattern Mix Module ]
---
---
--- keeps track on the mix patterns (and updates the other one)

class "PatternMix" (Module)

PatternMixData = {
    row = {
        mix_1 = "__stepp0r_mix_1",
        mix_2 = "__stepp0r_mix_2"
    },
}

function PatternMix:__init()
    self.pattern_mix_1              = nil
    self.pattern_mix_1_sequence_idx = nil
    self.pattern_mix_2              = nil
    self.pattern_mix_2_sequence_idx = nil
    --
    self.active_mix_pattern         = nil
    self.next_mix_pattern           = nil
    --
    self.__update_callbacks         = {}
    --
    self:__create_selected_pattern_idx_listener()
end

function PatternMix:_activate()
    self:__set_mix_patterns()
    self:__set_active_and_next_patterns()
    add_notifier(renoise.song().selected_pattern_index_observable, self.__selected_pattern_idx_listener)
    self:_update_callbacks()
end

function PatternMix:_deactivate()
    remove_notifier(renoise.song().selected_pattern_index_observable, self.__selected_pattern_idx_listener)
end

function PatternMix:__create_selected_pattern_idx_listener()
    self.__selected_pattern_idx_listener = function ()
        self:__set_active_and_next_patterns()
        if self.is_not_active then return end
        self:__adjuster_next_patterns()
        self:_update_callbacks()
    end
end



function PatternMix:_get_pattern_alias_idx(pattern, track_idx)
    if pattern and pattern.tracks[track_idx] and pattern.tracks[track_idx].is_alias then
        return pattern.tracks[track_idx].alias_pattern_index
    else
        return -1
    end
end

function PatternMix:__set_mix_patterns()
    local tupel = self:__find_mix_pattern(PatternMixData.row.mix_1)
    if tupel then
        self.pattern_mix_1              = tupel[2]
        self.pattern_mix_1_sequence_idx = tupel[1]
        print("found pattern_mix_1 at : ", self.pattern_mix_1_sequence_idx)
    end
    local tupel_2 = self:__find_mix_pattern(PatternMixData.row.mix_2)
    if tupel_2 then
        self.pattern_mix_2              = tupel_2[2]
        self.pattern_mix_2_sequence_idx = tupel_2[1]
        print("found pattern_mix_2 at : ", self.pattern_mix_2_sequence_idx)
    end
end

function PatternMix:__set_active_and_next_patterns()
    self.active_mix_pattern = self:_active_mix_pattern()
    print("found active_mix_pattern at : ", self.active_mix_pattern.name)
    self.next_mix_pattern   = self:_next_mix_pattern()
    print("found next_mix_pattern at : ", self.next_mix_pattern.name)
end

-- @returns the mix pattern which should be used to alias the next pattern in.
function PatternMix:_next_mix_pattern()
    if (self.pattern_mix_1 and self.pattern_mix_2) then
        if self.active_mix_pattern == self.pattern_mix_2 then
            return self.pattern_mix_1
        else
            return self.pattern_mix_2
        end
    end
    -- there is only one pattern mix available
    if self.pattern_mix_1 then
        return self.pattern_mix_1
    end
    if self.pattern_mix_2 then
        return self.pattern_mix_2
    end
end

function PatternMix:_active_mix_pattern()
    if (self.pattern_mix_1 and self.pattern_mix_2) then
        if renoise.song().selected_pattern == self.pattern_mix_2 then
            return self.pattern_mix_2
        else
            return self.pattern_mix_1
        end
    end
    -- there is only one pattern mix available
    if self.pattern_mix_1 then
        return self.pattern_mix_1
    end
    if self.pattern_mix_2 then
        return self.pattern_mix_2
    end
    return nil
end

function PatternMix:__find_mix_pattern(key)
    for sequence_idx,pattern_idx in pairs(renoise.song().sequencer.pattern_sequence) do
        local pattern = renoise.song().patterns[pattern_idx]
        if pattern.name == key then
            return {sequence_idx, pattern}
        end
    end
    return nil
end

function PatternMix:__all_tracks()
    local result = {}
    for track_idx = 1, table.getn(renoise.song().tracks) do
        result[track_idx] = track_idx
    end
    return result
end

function PatternMix:__adjuster_next_patterns()
    for _,track_idx in pairs(self:__all_tracks()) do
        local pattern_idx = self:_get_pattern_alias_idx(self.active_mix_pattern, track_idx)
        self:_set_mix_to_pattern(track_idx, pattern_idx)
    end
end

function PatternMix:_set_mix_to_pattern(track_idx, pattern_idx)
    -- get pattern
    local mix_pattern = self.next_mix_pattern
    if not mix_pattern then return end
    -- get track
    local track = mix_pattern.tracks[track_idx]
    if not track then return end
    --
    if pattern_idx ~= -1 then
        track.alias_pattern_index = pattern_idx
    end
end

function PatternMix:register_update_callback(callback)
    table.insert(self.__update_callbacks, callback)
end
function PatternMix:_update_callbacks()
    local update = {
        active    = self.active_mix_pattern,
        next      = self.next_mix_pattern,
        mix_1_idx = self.pattern_mix_1_sequence_idx,
        mix_2_idx = self.pattern_mix_2_sequence_idx
    }
    for _, callback in ipairs(self.__update_callbacks) do
        callback(update)
    end
end
