import argparse
import numpy as np
from astropy.table import Table
from astropy.coordinates import SkyCoord
import astropy.units as u

from Ska.Shell import bash
from Chandra.Time import DateTime


def get_options():
    parser = argparse.ArgumentParser(
        description="""Make a filtered version of dark_attitudes.dat using the zodiacal brightness
                       data from the attitude.pl CGI""")
    parser.add_argument("--date",
                        required=True,
                        help="Requested date of expected dark current calibration")
    opt = parser.parse_args()
    return opt


def filter_atts(date):
    """
    Run the attitude.pl Perl CGI with a date and return a filtered version to remake
    dark_attitudes.dat (since the FOT is already parsing that file, I want to return a
    file that is formatted the same way).

    :param date: Chandra.Time compatible date
    :returns: astropy table of dark attitudes filtered by zodiacal brightness limits
    """
    date = DateTime(date).date

    Z_LOW = 0
    Z_UP = 250
    zodi_annotated_html = bash(
        'perl ./attitude.pl date="{date}" type="ATT List" z_low="{z_low}" z_up="{z_up}"'.format(
            date=date[0:8], z_low=Z_LOW, z_up=Z_UP))
    zodi_list = Table.read(zodi_annotated_html, format='ascii.html')
    zodi_ok = (zodi_list['Zodi'] >= Z_LOW) & (zodi_list['Zodi'] <= Z_UP)
    zodi_ok_coords = SkyCoord(zodi_list[zodi_ok]['RA'], zodi_list[zodi_ok]['DEC'], unit='deg')

    all_atts = Table.read('full_dark_attitudes.dat', format='ascii.fixed_width_two_line')
    ok = []
    for att in all_atts:
        coord = SkyCoord(att['eq_ra'], att['eq_dec'], unit='deg')
        ok.append(np.any(coord.separation(zodi_ok_coords) < (1 * u.arcsec)))
    ok = np.array(ok)
    cut_list = all_atts[ok]
    return cut_list

if __name__ == '__main__':
    opt = get_options()
    date = DateTime(opt.date)
    cut_list = filter_atts(date)
    cut_list.write("dark_attitudes.dat",
                   format='ascii.fixed_width_two_line')
