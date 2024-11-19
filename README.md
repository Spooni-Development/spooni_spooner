# 💻 Spooner
Documentation relating to the [spooni_spooner](https://github.com/Spooni-Development/spooni_spooner).

## 1. Installation
spooni_spooner works Standalone. 

To install spooni_spooner:
- Download the resource
  - On [Github](https://github.com/Spooni-Development/spooni_spooner)
- Ensure that all requirements are installed
  - [uiprompt](https://github.com/kibook/redm-uiprompt)
- Drag and drop the resource into your resources folder
  - `spooni_spooner`
- Add this ensure in your server.cfg  
  ```
    ensure spooni_spooner
  ```
- Add the permissions' exec to the server.cfg
  ```
    exec @spooni_spooner/permissions.cfg
  ```
- Or define the permission yourself
  ```
  add_ace group.admin spooner.view allow
  add_ace group.admin spooner.spawn allow
  add_ace group.admin spooner.modify.own allow
  add_ace group.admin spooner.delete.own allow
  add_ace group.admin spooner.properties allow

  add_ace group.admin spooner.noEntityLimit allow
  add_ace group.admin spooner.modify.other allow
  add_ace group.admin spooner.delete.other allow
  ```
- At the end
  - Restart the server

If you have any problems, you can always open a ticket in the [Spooni Discord](https://discord.gg/spooni).

## 2. Usage
## Cursor colours

| Colour | Meaning            |
|--------|--------------------|
| white  | No entity selected |
| green  | Entity highlighted |
| blue   | Entity attached    |

## Controls

| Control                   | Function                                                                         |
|---------------------------|----------------------------------------------------------------------------------|
| W/A/S/D                   | Move                                                                             |
| Spacebar/Shift            | Up/Down                                                                          |
| E                         | Spawn                                                                            |
| Left click                | Entity highlighted: Attach, Entity attached: Detach                              |
| Right click               | Delete selected entity                                                           |
| C/V                       | Rotate                                                                           |
| B                         | Change rotation axis                                                             |
| Q/Z/Arrow keys            | Adjust selected entity position                                                  |
| I                         | Cycle between controlled mouse adjustment modes                                  |
| U                         | Toggle whether entities stick to the ground in controlled mouse adjustment modes |
| 7                         | Turn off mouse adjustment                                                        |
| 8                         | Return to Free mouse adjustment mode                                             |
| G                         | Clone selected entity                                                            |
| Pg Up/Pg Down/Mouse wheel | Change currently selected speed                                                  |
| R                         | Cycle between which speed to change                                              |
| F                         | Open the Spawn menu                                                              |
| X                         | Open the Database menu                                                           |
| Tab                       | Open the Properties menu for the selected entity                                 |
| J                         | Open the Save/Load Database menu                                                 |
| Delete                    | Exit Object Spooner                                                              |

## Menus

### Spawn menu - F

The **Spawn** menu provides searchable lists to select an entity to spawn. Left-clicking on an entity sets it as your current spawn.

If an entity is not included in the list, you can still spawn it by entering the full model name in the search field and clicking **Spawn By Name**.

Right-clicking an entity in any of the spawn menus will add that entity as a favourite. Clickin the favourites button will toggle displaying only your favourited entities.

### Database menu - X

The **Database** menu stores a list of entities. When an entity is spawned, it is automatically added to the current database. Existing entities can be added/removed from the database via the **Properties** menu.

- Left-click on an entity to open it in the **Properties** menu
- Right-click on an entity to delete it
- Click **Delete All** to delete all entities in the database

### Properties menu - Tab

The **Properties** menu lists and allows you to edit properties of an entity.

### Save/Load Database menu - J

The **Save/Load Database** menu allows you to store your current database with a name, and then load all the entities from it again later.

- To save your current database, enter name in the field and click **Save**.
- To load a saved database, left-click on the name of the database.
- To delete a saved database, right-click on the name of the database.
- To import a database or export the current database, click **Import/Export**.

Checking the **Load relative to cursor position** box will spawn the entities in the selected database relative to the current cursor position, rather than exactly where they were originally placed.

Checking the **Replace current DB** box will replace your current database with the loaded database, rather than merging the two.

Checking the **Save/Load deletions** box will save what entities you delete, and delete them again when the database is loaded.

### Import/Export menu

The **Import/Export** menu allows you to import and export databases in a number of different formats:

| Format          | Description | Export? | Import? |
|-----------------|-------------|---------|---------|
| YMAP            | Native map format used by RDR2 | Yes | Yes |
| Prop Loader     | Format used by the [spooni_prop_loader](https://spooni-mapping.tebex.io/package/6284606) resource | Yes | Yes |
| Map Editor XML  | XML format used by the [Lambdarevolution map editor](https://allmods.net/red-dead-redemption-2/tools-red-dead-redemption-2/rdr2-map-editor-v0-10/) and the [objectloader](https://github.com/kibook/redm-objectloader) resource | Yes | Yes |
| Spooner DB JSON | The native format used by the spooner | Yes | Yes |
| Spooner Backup  | Backup of all spooner databases | Yes | Yes |
| propplacer JSON | [RedEM:RP propplacer](https://github.com/RedEM-RP/redemrp_propplacer) JSON database | Yes | No |

To export, select the desired format and click **Export**. The output will be displayed in the text box, and you can copy it to save it to an external file.

To import, paste the input into the text box, select the appropriate format, and click **Import**. Objects imported will be added to your current database.

Entering a URL of a JSON/XML file in the **Import from URL** field and clicking **Import** allows you to import from external web sources, such as pastebin.com, without needing to copy and paste. Be sure that the URL points to the raw version of the file when using such services.

## 3. Credits

Big thanks go to [kibook](https://github.com/kibook) the creator of the main script, since the script is already 2 years old (as of 2024) we wanted to give it a little overhaul.

Click here for the [original script](https://github.com/kibook/spooner)
