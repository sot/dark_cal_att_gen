objects = attitude.pl dark_attitudes.dat table_17.csv

test:

doc:

install: $(objects)
	rsync --times --cvs-exclude $(objects) /proj/sot/ska/www/ASPECT/dark_att_generator/
	wget -O index.html http://asc.harvard.edu/mta/ASPECT/dark_att_generator/attitude.pl
	rsync --times --cvs-exclude index.html /proj/sot/ska/www/ASPECT/dark_att_generator/

test: $(objects) test_ATTList_2005001 test_ORList_2005001
	./attitude.pl date="2005:001" type="ATT List" z_low="0" z_up="250" > new_test_ATTList
	./attitude.pl date="2005:001" type="OR List" z_low="0" z_up="250"  > new_test_ORList
	diff new_test_ATTList test_ATTList_2005001
	diff new_test_ORList test_ORList_2005001

