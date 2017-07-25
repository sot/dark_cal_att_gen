# Set the task name
TASK = dark_cal_att_gen

FLIGHT_ENV = SKA

SHARE = attitude.pl filter_atts_for_fot.py
DATA = full_dark_attitudes.dat table_17.csv task_schedule.cfg

webfiles = index.html
cxcwebloc = /proj/sot/ska/www/ASPECT/dark_att_generator/

install: $(webfiles)
	rsync -v --times --cvs-exclude $(webfiles) $(cxcwebloc)
	mkdir -p $(INSTALL_DATA)
	mkdir -p $(INSTALL_SHARE)
	rsync --times --cvs-exclude $(SHARE) $(INSTALL_SHARE)
	rsync --times --cvs-exclude $(DATA) $(INSTALL_DATA)


