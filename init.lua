--------------------------------------------------------
-- supporting junk


function min(a,b)
    if a < b then
        return a;
    else
        return b;
    end
end

--------------------------------------------------------

sorters = {
    wise = function(a,b)
        if(a == nil) then
            if b == nil then
                return true;
            else
                return false;
            end
        elseif b == nil then
            return true;
        end

        local aname = a:get_name();
        local bname = b:get_name();
        print('aname: '..aname..', bname: '..bname)
        if(string.len(aname) == 0) then
            return false;
        end
        if(string.len(bname) == 0) then
            return true;
        end
        if (aname ~= bname) then
            return aname < bname;
        end
        -- may need to collapse the two together!
        local bothmax = a:get_stack_max();
        if bothmax == 1 then
            -- it's unstackable                
            local awear = a:get_wear();
            local bwear = b:get_wear();
            return awear < bwear;
        end
        local acount = a:get_count();
        local bcount = b:get_count();
        if(acount == bothmax) then
            return true;
        elseif (bcount == bothmax) then
            return false;
        end
        local num = min(bcount,bothmax-acount);
        a:add_item(b:take_item(num));
        -- nothing can have both count AND wear, right?
        return true;
    end,
    amount = function(a,b)
        return a:get_count() < b:get_count()
    end,
    wear = function(a,b)
        return a:get_wear() < b:get_wear()
    end,
}

function registerWand(method,sorter)
    if method == nil then
        name = "chest_sorter:wand";
        sorter = sorters.wise;
        assert(sorter ~= nil);
        desc = 'Chest Sorter';
        image = 'chest_sorter_wand.png';
    else
        name = "chest_sorter:wand_"..method;
        desc = "Chest Sorter ("..method..')';
        image = 'chest_sorter_wand_'..method..'.png'
    end

    minetest.register_tool(name, {
        description = desc,
        inventory_image = image,
        wield_image = image,
        stack_max = 1,
        tool_capabilities = {
            full_punch_interval=0,
            max_drop_level=0
        },
        on_use = function(self,user,punched) 
            local pos = minetest.get_pointed_thing_position(punched);
            local meta = minetest.get_meta(pos);
            local inv = meta:get_inventory();
            if(inv == nil) then
                minetest.chat_send_player(user:get_player_name(),"That can't be sorted.","Sorter -!-");
                return;
            end
            -- this isn't exported, but default locked chest does this
            local owner = meta:get_string("owner");
            if(owner ~= nil and string.len(owner) ~= 0 and user:get_player_name() ~= owner) then
                minetest.chat_send_player(user:get_player_name(),"That's not yours!","Sorter -!-");
                return;
            end
            -- Sokomine's shared chest locks
            if locks ~= nil and not locks:lock_allow_use(pos,user) then
                minetest.chat_send_player(user:get_player_name(),"That's not yours!","Sorter -!-");
            end

            local tabl = meta:to_table()
            inv = tabl["inventory"]["main"];
            if(inv == nil) then
                -- we don't sort furnaces!
                return;
            end

            table.sort(inv,sorter);
            -- note take_item will set the name to '' when empty
            -- NEVER reduce the inventory array size for chests
            meta:from_table(tabl);
            minetest.chat_send_player(user:get_player_name(),"Sorted.","Sorter -!-");
        end
    });
end

for name,sorter in pairs(sorters) do
    registerWand(name,sorter);
end

registerWand();
