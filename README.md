# discord-scoreboard
An automatic Discord scoreboard for FiveM servers using QB-Core. It posts and updates one embed in Discord using a webhook, showing the total number of players online and how many are currently on duty in groups such as police, medical, and businesses.

Any questions my Discord is @KozmicAbby or https://discord.gg/8zKFMYWkkt. I will NOT response to messages without a clear question or concern. "Hey" will be ignored. 

<img width="240" height="149" alt="image" src="https://github.com/user-attachments/assets/4230c837-c8e8-4427-b3fd-42d7b7517249" />

# Features
- Displays total online players with max slots  
- Counts on-duty staff across configured job groups  
- Refreshes on interval + instantly on join/leave/duty changes  
- Edits the same message instead of sending new posts  
- Easy configuration in `config.lua`  

# Setup
1. Add your Discord **webhook URL** in `config.lua`.
2. Adjust jobs in the config, if you'd like to remove a catagory remove it from the `server.lua`.
3. Adjust the embed title, color, and groups if needed.  
4. Start the resource after `qb-core`.  

This goes into your resource folder, make sure that it's ensured then it will update every X amount of seconds!

# Common Issues
- If you have posted it in a channel, then moved the webhook. Delete the old message then the new one will pop up in your desired spot!
