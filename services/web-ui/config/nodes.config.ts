import { IconType } from 'react-icons'
import { FaTiktok, FaYoutube, FaFacebook, FaInstagram, FaTwitter, FaLink, FaTag, FaFileCsv, FaChartBar, FaChartLine, FaChartPie, FaChartArea, FaDotCircle, FaExclamationTriangle, FaDatabase, FaRandom, FaCodeBranch, FaFilter, FaCalendarAlt } from 'react-icons/fa'
import { SiOpenai } from 'react-icons/si'
import { BiData } from 'react-icons/bi'
import { MdStorage, MdTextFields, MdNumbers, MdViewList, MdDataObject, MdSubject, MdFileUpload, MdPictureAsPdf, MdTrendingUp } from 'react-icons/md'
import { TbChartDonut } from 'react-icons/tb'

export interface NodeLink {
  type: 'input' | 'requirement' | 'output'
  label: string
  max_connect: number
  data_type: string[]
}

export interface NodeConfig {
  id: string
  name: string
  group: string
  icon: IconType
  theme_color: string
  shape: 0 | 1 | 2
  links: NodeLink[]
}

export const nodesConfig: NodeConfig[] = [
  {
    id: 'tiktok',
    name: 'TikTok',
    group: 'Social Media',
    icon: FaTiktok,
    theme_color: '#000000',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Input',
        max_connect: 1,
        data_type: ['array', 'string']
      },
      {
        type: 'requirement',
        label: 'API Key',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'requirement',
        label: 'Keyword',
        max_connect: 1,
        data_type: ['array', 'string']
      },
      {
        type: 'output',
        label: 'Output',
        max_connect: 999,
        data_type: ['array', 'string']
      }
    ]
  },
  {
    id: 'youtube',
    name: 'YouTube',
    group: 'Social Media',
    icon: FaYoutube,
    theme_color: '#FF0000',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Input',
        max_connect: 1,
        data_type: ['array', 'string']
      },
      {
        type: 'requirement',
        label: 'API Key',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'output',
        label: 'Output',
        max_connect: 999,
        data_type: ['array', 'string']
      }
    ]
  },
  {
    id: 'facebook',
    name: 'Facebook',
    group: 'Social Media',
    icon: FaFacebook,
    theme_color: '#1877F2',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Input',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'requirement',
        label: 'Access Token',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'output',
        label: 'Output',
        max_connect: 999,
        data_type: ['object']
      }
    ]
  },
  {
    id: 'instagram',
    name: 'Instagram',
    group: 'Social Media',
    icon: FaInstagram,
    theme_color: '#E4405F',
    shape: 2,
    links: [
      {
        type: 'input',
        label: 'Input',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'output',
        label: 'Output',
        max_connect: 999,
        data_type: ['array']
      }
    ]
  },
  {
    id: 'twitter',
    name: 'Twitter',
    group: 'Social Media',
    icon: FaTwitter,
    theme_color: '#1DA1F2',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Input',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'requirement',
        label: 'Bearer Token',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'output',
        label: 'Output',
        max_connect: 999,
        data_type: ['array']
      }
    ]
  },
  {
    id: 'openai',
    name: 'OpenAI',
    group: 'AI',
    icon: SiOpenai,
    theme_color: '#412991',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Prompt',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'requirement',
        label: 'API Key',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'output',
        label: 'Response',
        max_connect: 999,
        data_type: ['string', 'object']
      }
    ]
  },
  {
    id: 'data-processor',
    name: 'Data Processor',
    group: 'Processing',
    icon: BiData,
    theme_color: '#10B981',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Input',
        max_connect: 5,
        data_type: ['array', 'object', 'string']
      },
      {
        type: 'output',
        label: 'Output',
        max_connect: 999,
        data_type: ['array', 'object']
      }
    ]
  },
  {
    id: 'storage',
    name: 'Storage',
    group: 'Processing',
    icon: MdStorage,
    theme_color: '#F59E0B',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object', 'string']
      },
      {
        type: 'requirement',
        label: 'Config',
        max_connect: 1,
        data_type: ['object']
      },
      {
        type: 'output',
        label: 'Status',
        max_connect: 1,
        data_type: ['string']
      }
    ]
  },
  {
    id: 'input-string',
    name: 'String',
    group: 'Basic',
    icon: MdTextFields,
    theme_color: '#8B5CF6',
    shape: 0,
    links: [
      {
        type: 'output',
        label: 'Value',
        max_connect: 999,
        data_type: ['string']
      }
    ]
  },
  {
    id: 'input-int',
    name: 'Integer',
    group: 'Basic',
    icon: MdNumbers,
    theme_color: '#06B6D4',
    shape: 0,
    links: [
      {
        type: 'output',
        label: 'Value',
        max_connect: 999,
        data_type: ['number', 'int']
      }
    ]
  },
  {
    id: 'input-array',
    name: 'Array',
    group: 'Basic',
    icon: MdViewList,
    theme_color: '#EC4899',
    shape: 0,
    links: [
      {
        type: 'output',
        label: 'Items',
        max_connect: 999,
        data_type: ['array']
      }
    ]
  },
  {
    id: 'input-json',
    name: 'JSON',
    group: 'Basic',
    icon: MdDataObject,
    theme_color: '#14B8A6',
    shape: 0,
    links: [
      {
        type: 'output',
        label: 'Data',
        max_connect: 999,
        data_type: ['object', 'json']
      }
    ]
  },
  {
    id: 'input-textarea',
    name: 'Text Area',
    group: 'Basic',
    icon: MdSubject,
    theme_color: '#F97316',
    shape: 1,
    links: [
      {
        type: 'output',
        label: 'Text',
        max_connect: 999,
        data_type: ['string', 'text']
      }
    ]
  },

  {
    id: 'url',
    name: 'URL',
    group: 'Basic',
    icon: FaLink,
    theme_color: '#3B82F6',
    shape: 0,
    links: [
      {
        type: 'output',
        label: 'URL',
        max_connect: 999,
        data_type: ['string', 'url']
      }
    ]
  },
  {
    id: 'category',
    name: 'Category',
    group: 'Basic',
    icon: FaTag,
    theme_color: '#A855F7',
    shape: 0,
    links: [
      {
        type: 'output',
        label: 'Category',
        max_connect: 999,
        data_type: ['string']
      }
    ]
  },
  {
    id: 'csv-data',
    name: 'CSV',
    group: 'Basic',
    icon: FaFileCsv,
    theme_color: '#059669',
    shape: 0,
    links: [
      {
        type: 'output',
        label: 'Data',
        max_connect: 999,
        data_type: ['array', 'csv']
      }
    ]
  },
  {
    id: 'time-range',
    name: 'Time Range',
    group: 'Basic',
    icon: FaCalendarAlt,
    theme_color: '#F59E0B',
    shape: 1,
    links: [
      {
        type: 'output',
        label: 'From',
        max_connect: 999,
        data_type: ['date', 'string']
      },
      {
        type: 'output',
        label: 'To',
        max_connect: 999,
        data_type: ['date', 'string']
      }
    ]
  },

  {
    id: 'extract-csv',
    name: 'Extract CSV',
    group: 'Output',
    icon: MdFileUpload,
    theme_color: '#10B981',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'output',
        label: 'File',
        max_connect: 1,
        data_type: ['file', 'csv']
      }
    ]
  },
  {
    id: 'extract-pdf',
    name: 'Extract PDF',
    group: 'Output',
    icon: MdPictureAsPdf,
    theme_color: '#DC2626',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Content',
        max_connect: 1,
        data_type: ['string', 'html', 'object']
      },
      {
        type: 'output',
        label: 'File',
        max_connect: 1,
        data_type: ['file', 'pdf']
      }
    ]
  },

  {
    id: 'bar-chart',
    name: 'Bar Chart',
    group: 'Charts',
    icon: FaChartBar,
    theme_color: '#3B82F6',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'requirement',
        label: 'Config',
        max_connect: 1,
        data_type: ['object']
      },
      {
        type: 'output',
        label: 'Chart',
        max_connect: 1,
        data_type: ['chart', 'image']
      }
    ]
  },
  {
    id: 'line-chart',
    name: 'Line Chart',
    group: 'Charts',
    icon: FaChartLine,
    theme_color: '#10B981',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'requirement',
        label: 'Config',
        max_connect: 1,
        data_type: ['object']
      },
      {
        type: 'output',
        label: 'Chart',
        max_connect: 1,
        data_type: ['chart', 'image']
      }
    ]
  },
  {
    id: 'doughnut-chart',
    name: 'Doughnut',
    group: 'Charts',
    icon: TbChartDonut,
    theme_color: '#F59E0B',
    shape: 2,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'output',
        label: 'Chart',
        max_connect: 1,
        data_type: ['chart', 'image']
      }
    ]
  },
  {
    id: 'pie-chart',
    name: 'Pie Chart',
    group: 'Charts',
    icon: FaChartPie,
    theme_color: '#EC4899',
    shape: 2,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'output',
        label: 'Chart',
        max_connect: 1,
        data_type: ['chart', 'image']
      }
    ]
  },
  {
    id: 'area-chart',
    name: 'Area Chart',
    group: 'Charts',
    icon: FaChartArea,
    theme_color: '#8B5CF6',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'requirement',
        label: 'Config',
        max_connect: 1,
        data_type: ['object']
      },
      {
        type: 'output',
        label: 'Chart',
        max_connect: 1,
        data_type: ['chart', 'image']
      }
    ]
  },
  {
    id: 'scatter-chart',
    name: 'Scatter Plot',
    group: 'Charts',
    icon: FaDotCircle,
    theme_color: '#06B6D4',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'requirement',
        label: 'Config',
        max_connect: 1,
        data_type: ['object']
      },
      {
        type: 'output',
        label: 'Chart',
        max_connect: 1,
        data_type: ['chart', 'image']
      }
    ]
  },

  {
    id: 'comparer',
    name: 'Comparer',
    group: 'Action',
    icon: FaRandom,
    theme_color: '#8B5CF6',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Value A',
        max_connect: 1,
        data_type: ['any']
      },
      {
        type: 'input',
        label: 'Value B',
        max_connect: 1,
        data_type: ['any']
      },
      {
        type: 'requirement',
        label: 'Operator',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'output',
        label: 'Result',
        max_connect: 999,
        data_type: ['boolean']
      }
    ]
  },
  {
    id: 'alert',
    name: 'Alert',
    group: 'Action',
    icon: FaExclamationTriangle,
    theme_color: '#EF4444',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Message',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'requirement',
        label: 'Condition',
        max_connect: 1,
        data_type: ['boolean']
      },
      {
        type: 'output',
        label: 'Status',
        max_connect: 1,
        data_type: ['string']
      }
    ]
  },
  {
    id: 'save-to-db',
    name: 'Save To DB',
    group: 'Action',
    icon: FaDatabase,
    theme_color: '#0891B2',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'requirement',
        label: 'Table',
        max_connect: 1,
        data_type: ['string']
      },
      {
        type: 'output',
        label: 'Status',
        max_connect: 1,
        data_type: ['string', 'object']
      }
    ]
  },
  {
    id: 'trending-tracker',
    name: 'Trending Tracker',
    group: 'Action',
    icon: MdTrendingUp,
    theme_color: '#10B981',
    shape: 1,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array', 'object']
      },
      {
        type: 'requirement',
        label: 'Timeframe',
        max_connect: 1,
        data_type: ['string', 'number']
      },
      {
        type: 'output',
        label: 'Trends',
        max_connect: 999,
        data_type: ['array', 'object']
      }
    ]
  },
  {
    id: 'condition',
    name: 'Condition',
    group: 'Action',
    icon: FaCodeBranch,
    theme_color: '#F59E0B',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Input',
        max_connect: 1,
        data_type: ['any']
      },
      {
        type: 'requirement',
        label: 'Rule',
        max_connect: 1,
        data_type: ['string', 'object']
      },
      {
        type: 'output',
        label: 'True',
        max_connect: 999,
        data_type: ['any']
      },
      {
        type: 'output',
        label: 'False',
        max_connect: 999,
        data_type: ['any']
      }
    ]
  },
  {
    id: 'filter',
    name: 'Filter',
    group: 'Action',
    icon: FaFilter,
    theme_color: '#6366F1',
    shape: 0,
    links: [
      {
        type: 'input',
        label: 'Data',
        max_connect: 1,
        data_type: ['array']
      },
      {
        type: 'requirement',
        label: 'Criteria',
        max_connect: 1,
        data_type: ['string', 'object']
      },
      {
        type: 'output',
        label: 'Filtered',
        max_connect: 999,
        data_type: ['array']
      }
    ]
  }
]
