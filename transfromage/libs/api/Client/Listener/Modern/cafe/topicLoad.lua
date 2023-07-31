local Topic = require("api/Entities/cafe/Topic")

local onCafeTopicLoad = function(self, packet, connection, identifiers)
	local cafe = self.cafe

	packet:read8() -- ?

	local topicId, tmpTopic = packet:read32()
	if not cafe.topicsById[topicId] then
		tmpTopic = Topic:new(self, nil, topicId)

		cafe.topicsById[topicId] = tmpTopic
		cafe.topics[#cafe.topics + 1] = tmpTopic
	end

	local topic = cafe.topicsById[topicId]
	topic:retrieveMessages(packet)

	--[[@
		@name cafeTopicLoad
		@desc Triggered when a Café topic is opened or refreshed.
		@param topic<table> The data of the topic.
		@struct @topic
		{
			id = 0, -- The id of the topic.
			title = "", -- The title of the topic.
			authorId = 0, -- The id of the topic author.
			posts = 0, -- The number of messages in the topic.
			lastUserName = "", -- The name of the last user that posted in the topic.
			timestamp = 0, -- When the topic was created.
			author = "", -- The name of the topic author.
			messages = {
				[i] = {
					topicId = 0, -- The id of the topic where the message is located.
					id = 0, -- The id of the message.
					authorId = 0, -- The id of the topic author.
					timestamp = 0, -- When the topic was created.
					author = "", -- The name of the topic author.
					content = "", -- The content of the message.
					canLike = false, -- Whether the account can like/dislike the message.
					likes = 0 -- The number of likes on the message.
				}
			}
		}
	]]
	self.event:emit("cafeTopicLoad", topic)

	local messages, tmpMessage = topic.messages
	local cachedMessages = cafe.cachedMessages
	if not cachedMessages[topic.id] then
		cachedMessages[topic.id] = { }
		cachedMessages = cachedMessages[topic.id]
	end

	for i = 1, #messages do -- Unfortunately I couldn't make it decrescent, otherwise it would trigger the events in the wrong order
		tmpMessage = messages[i]

		if not cachedMessages[tmpMessage.id] then
			cachedMessages[tmpMessage.id] = true

			--[[@
				@name cafeTopicMessage
				@desc Triggered when a new message in a Café topic is cached.
				@param message<table> The data of the message.
				@param topic<table> The data of the topic.
				@struct @message
				{
					topicId = 0, -- The id of the topic where the message is located.
					id = 0, -- The id of the message.
					authorId = 0, -- The id of the topic author.
					timestamp = 0, -- When the topic was created.
					author = "", -- The name of the topic author.
					content = "", -- The content of the message.
					canLike = false, -- Whether the account can like/dislike the message.
					likes = 0 -- The number of likes on the message.
				}
				@struct @topic
				{
					id = 0, -- The id of the topic.
					title = "", -- The title of the topic.
					authorId = 0, -- The id of the topic author.
					posts = 0, -- The number of messages in the topic.
					lastUserName = "", -- The name of the last user that posted in the topic.
					timestamp = 0, -- When the topic was created.
					author = "", -- The name of the topic author.
					messages = {
						[i] = {
							topicId = 0, -- The id of the topic where the message is located.
							id = 0, -- The id of the message.
							authorId = 0, -- The id of the topic author.
							timestamp = 0, -- When the topic was created.
							author = "", -- The name of the topic author.
							content = "", -- The content of the message.
							canLike = false, -- Whether the account can like/dislike the message.
							likes = 0 -- The number of likes on the message.
						}
					}
				}
			]]
			self.event:emit("cafeTopicMessage", tmpMessage, topic)
		end
	end
end

return { onCafeTopicLoad, 30, 41 }