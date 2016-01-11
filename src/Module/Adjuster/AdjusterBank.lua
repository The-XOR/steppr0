--- ======================================================================================================
---
---                                                 [ Bank of Selection ]
---


function Adjuster:__init_bank()
    self.bank_matrix = {}
    self:__create_current_observer()
    self:__create_mode_observer()
end

function Adjuster:__activate_bank()
    self.current_store = self.store.current
    self.mode    = self.store.mode
    self:_clear_bank_matrix()
    self:_update_bank_matrix()
    add_notifier(self.store.current_observable, self.current_observer)
    add_notifier(self.store.mode_observable, self.mode_observer)
end

function Adjuster:__deactivate_bank()
    remove_notifier(self.store.mode_observable, self.mode_observer)
    remove_notifier(self.store.current_observable, self.current_observer)
    self:_clear_bank_matrix()
end

function Adjuster:wire_store(store)
    self.store = store
end
function Adjuster:__create_current_observer()
    self.current_observer = function()
        self.current_store = self.store.current
        if self.is_active then
            self:_refresh_matrix()
        end
    end
end
function Adjuster:__create_mode_observer()
    self.mode_observer = function()
        self.mode = self.store.mode
    end
end

--- ------------------------------------------------------------------------------------------------------
---
---                                                 [ Lib ]



function Adjuster:_paste(line)
    self.current_store:paste_entry(line, self.instrument_idx, self:active_pattern())
end
function Adjuster:_copy(line_start, line_stop)
    self.current_store:copy(self.pattern_idx, self.track_idx, line_start, line_stop)
end
function Adjuster:_clear(line_start, line_stop)
    self.current_store:clear(line_start, line_stop)
end



--- ------------------------------------------------------------------------------------------------------
---
---                                                 [ Bank Matrix ]

--- updates the matrix (which will be rendered afterwards)
function Adjuster:_update_bank_matrix()

    local color = function(line)
        local bank_entry = self.current_store:selection(line)
        if bank_entry == Entry.SELECTED then
            return self.color.selected.on
        else
            return nil
        end
    end

    for line = self.page_start, (self.page_end - 1) do
        local xy = self:line_to_point(line)
        if xy then
            local x = xy[1]
            local y = xy[2]
            self.bank_matrix[x][y] = color(line)
        end
    end
end
function Adjuster:_update_bank_matrix_position(x,y)

    local color = function(line)
        local bank_entry = self.current_store:selection(line)
        if bank_entry == Entry.SELECTED then
            return self.color.selected.on
        else
            return nil
        end
    end

    local line = self:point_to_line(x,y)
    if not line then return end
    self.bank_matrix[x][y] = color(line)
end

function Adjuster:_clear_bank_matrix()
    self.bank_matrix = {}
    for x = 1, 8 do self.bank_matrix[x] = {} end
end

