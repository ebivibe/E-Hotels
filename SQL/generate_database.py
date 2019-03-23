w=open("Database.sql", "w+")

with open("Schemas.sql", "r") as f:
        w.write(f.read())   

with open("Triggers.sql", "r") as f:
        w.write(f.read())
     
with open("Views.sql", "r") as f:
        w.write(f.read())

with open("MockData.sql", "r") as f:
        w.write(f.read())
     


