using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using Nest;

namespace PowerSearch
{
    [Cmdlet(VerbsCommon.New, "ElasticClient")]
    public class NewElasticClient : PSCmdlet
    {
        private static Uri ServerUri = new Uri("http://localhost:9200");
        private static ConnectionSettings Settings = new ConnectionSettings(ServerUri, null);

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        public string Server
        {
            get { return ServerUri.ToString(); }
            set { ServerUri = new Uri(value); }
        }

        [Parameter()]
        public ConnectionSettings ConnectionSettings
        {
            get { return Settings; }
            set { Settings = value; }
        }

        protected override void ProcessRecord()
        {
            WriteObject(new ElasticClient(Settings));
        }
    }
}