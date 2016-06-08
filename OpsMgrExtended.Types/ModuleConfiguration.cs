using System;
using System.Collections.Generic;
using System.Text;

namespace OpsMgrExtended
{
    public class ModuleConfiguration
    {
        private string name;
        private string config;
        private string membername;
        private string runasmp;
        private string runas;

        public string ModuleTypeName
        {
            get { return name; }
            set { name = value; }
        }

        public string Configuration
        {
            get { return config; }
            set { config = value; }
        }

        public string MemberModuleName
        {
            get { return membername; }
            set { membername = value; }
        }

        public string RunAsMPName
        {
            get { return runasmp; }
            set { runasmp = value; }
        }

        public string RunAsName
        {
            get { return runas; }
            set { runas = value; }
        }
    }
}
