return {
   APPLICATION_COMMANDS            = '/applications/%s/commands',                  -- application.id | GET, POST
   APPLICATION_COMMANDS_EDIT       = '/applications/%s/commands/%s',               -- application.id, id | PATCH, DELETE
   APPLICATION_GUILD_COMMANDS      = '/applications/%s/guilds/%s/commands',        -- application.id, guild.id | GET, POST
   APPLICATION_GUILD_COMMANDS_EDIT = '/applications/%s/guilds/%s/commands/%',      -- application.id, guild.id, id | PATCH, DELETE
   INTERACTION_CALLBACK            = '/interactions/%s/%s/callback',               -- interaction.id, interaction.token | POST (gateway)
   INTERACTION_MESSAGES            = '/webhooks/%s/%s/messages/@original',         -- interaction.id, interaction.token | PATCH, DELETE (gateway)
   INTERACTION_FOLLOWUP            = '/webhooks/%s/%s/messages',                   -- interaction.id, interaction.token | POST (webhook)
   INTERACTION_FOLLOWUP_EDIT       = '/webhooks/%s/%s/messages/%s',                -- interaction.id, interaction.token | PATCH, DELETE (webhook)
}