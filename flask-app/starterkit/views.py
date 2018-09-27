# -*- coding: utf-8; mode: python -*-

from django.http import HttpResponse
from django.template import loader
from django.utils.translation import ugettext_lazy as _


def homepage(request):
    template = loader.get_template("homepage.html")
    context = {"whom": request.GET.get("hello", _("world")).title()}
    return HttpResponse(template.render(context, request))
