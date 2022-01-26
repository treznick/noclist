# frozen_string_literal: true

require_relative 'lib/client'
require_relative 'lib/formatter'

Formatter.format(Client.run)
exit 0
