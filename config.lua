Config = {}


Config.WebhookURL = 'https://discord.com/api/webhooks/1411810841845698632/-Tz5j0YysNRsy2-YF9NP2ZDFv2WkEpWhEU40kDKB8o_FsZi9iq9BnP-TXgrkEm4XSgmN'  -- e.g. 'https://discord.com/api/webhooks/123/abc...'

Config.Embed = {
    Title = 'SERVER NAME • Server Info',
    Color = 0xF39C12, -- orange
    Footer = 'Auto-updating scoreboard',
    Thumbnail = '' -- optional, leave '' to skip
}

-- How often to refresh (also refreshes instantly on duty/job changes)
Config.RefreshSeconds = 60

Config.ShowPlayersOnline = true
Config.MaxPlayers = 64

-- Group order is preserved here
Config.Groups = {
    Police    = { 'police', 'bcso', 'sasp', 'sapr', 'pd' },
    Medical   = { 'ambulance', 'ems' },
    Mechanics = { 'mechanic' },
    TunerShop = { 'tuners' },
    Food      = { 'yellowjack', 'coffeeshop' },
    Clubs     = { 'bahamamamas' },
    SpaWeed   = { 'koi' },
    Lawyers   = { 'lawyer' }
}