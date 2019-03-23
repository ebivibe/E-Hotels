f=open("Database.sql", "w+")

schemas=open("Schemas.sql", "r")
contents=schemas.read()
f.write(contents)

triggers=open("Triggers.sql", "r")
contents=triggers.read()
f.write(contents)

views=open("Views.sql", "r")
contents=views.read()
f.write(contents)

mockdata=open("MockData.sql", "r")
contents=mockdata.read()
f.write(contents)

     


