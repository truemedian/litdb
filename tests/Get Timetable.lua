local edulink = require("../main.lua")
edulink.authenticate("student@school.org", "Password", "Postcode")

local timetable = edulink.timetable()

local tabstart = string.format("%-7s| %-30s| %-20s| %-10s|", "Period", "Subject", "Teachers", "Room")
print(tabstart)
print(string.rep("-", #tabstart))

for i,v in pairs(timetable) do
  print(string.format("%-7s| %-30s| %-20s| %-10s|", i, v.teaching_group.subject, v.teachers, v.room.name))
end

print("Please check with edulink to ensure the correct day is being checked - this may not always be accurate.")
p("Please update this script to add the time checking function for the timetable sequence!")