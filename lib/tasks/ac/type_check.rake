# frozen_string_literal: true

namespace :ac do
  desc 'Run type checking using TypeScript Compiler'
  task :type_check do
    `npx tsc --noEmit`
  end

  desc 'Watch for type errors using TypeScript Compiler'
  task :watch_type_check do
    `npx tsc --noEmit --watch`
  end
end
