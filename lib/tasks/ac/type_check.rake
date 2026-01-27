# frozen_string_literal: true

namespace :ac do
  desc 'Run type checking using TypeScript Compiler'
  task :type_check do
    `npx tsc --noEmit`
  end
end
