using System;
using System.Collections.Generic;
using System.Text;

namespace OpsMgrExtended
{
    public class AlertConfiguration
    {
        private string stringresource;
        private string languagepackid;
        private string alertname;
        private string alertdescription;
        public string StringResourceName
        {
            get { return stringresource; }
            set { stringresource = value; }
        }
        public string LanguagePackID
        {
            get { return languagepackid; }
            set
            {
                if (value.Length != 3)
                {
                    throw new ArgumentException("The Language Pack Id must be exactly 3 characters in length");
                }
                else
                {
                    languagepackid = value;
                }
                
            }
        }
        public string AlertName
        {
            get { return alertname; }
            set { alertname = value; }
        }
        public string AlertDescription
        {
            get { return alertdescription; }
            set { alertdescription = value; }
        }

        public string StringResource
        {
            get { return stringresource; }
            set { stringresource = value; }
        }
    }
}
