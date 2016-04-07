#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Zekt'
SITENAME = 'Zekt\'s Blog'
SITESUBTITLE = 'Source of Love and Hatred.'
SITEURL = ''
THEME = './themes/blueidea'

PATH = ''
TIMEZONE = 'Europe/Paris'

DEFAULT_LANG = 'zh'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

# Blogroll
LINKS = (('Pelican', 'http://getpelican.com/'),
         ('Python.org', 'http://python.org/'),
         ('Jinja2', 'http://jinja.pocoo.org/'))

# Social widget
SOCIAL = (('Facebook', 'https://www.facebook.com/victorreznovisalive'),
        ('Github', 'https://github.com/Zekt'))

DEFAULT_PAGINATION = 10

# DISQUS
DISQUS_SITENAME = 'zekt'

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True

# Elegant
LANDING_PAGE_ABOUT = {
        'title': '在學科間徘徊的弱弱大學生',
        'details': '我是林子期，臺灣大學資管系二年級的學生，對開源與自由軟體、電腦科學、哲學、社會科學有興趣，希望能用知識與技術的力量，尋找不幸與不安的解答。'
        }
