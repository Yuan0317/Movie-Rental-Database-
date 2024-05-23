
 # Overview
 
 Developed a full-stack database project utilizing Oracle for backend database management. Established complex views and implemented triggers on these views to facilitate updates to underlying tables effectively. Integrated the database with Microsoft Access via ODBC, using Access forms as the user interface for clear and straightforward data management. 
 This setup enabled users to manage data efficiently without complex operations.

 ## Introduction：
 
 When the clerk opens Access, there will be a menu file, here selected three forms to facilitate the clerk management
 
 ![Screenshot 2024-04-22 141644](https://github.com/Yuan0317/Movie-Rental-Database-/assets/125390414/774057fb-8e0c-40f0-b32f-fe90797aedeb)

 Click on the first form, you can clearly see that here you can add, delete and change the movie stock or movie information.
 ![Screenshot 2024-04-22 141854](https://github.com/Yuan0317/Movie-Rental-Database-/assets/125390414/e707d08a-0014-423b-91a3-d4498654de94)

The underlying settings of this form is more complex, is the practice of PL/SQL trigger, first of all, the basic form based on several tables linked to the establishment of the view, but also in oracle on the establishment of the view trigger, and the following part of the history is another table, because the view of the additions, deletions and changes to change the record.
And all the clerk to this form of change, will change all the underlying tables in oracle, through the whole practice, you can be more comfortable with the use of oracle's advanced features, pl/sql practice, access and proficiency in the use of odbc links.

![Screenshot 2024-04-22 143356](https://github.com/Yuan0317/Movie-Rental-Database-/assets/125390414/b929b372-5947-4032-9c7c-918531ddfe30)

![Screenshot 2024-04-22 143319](https://github.com/Yuan0317/Movie-Rental-Database-/assets/125390414/f04e3de4-965c-4375-847b-05bac3e5437a)
