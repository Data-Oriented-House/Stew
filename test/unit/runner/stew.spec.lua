local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Stew = require(ReplicatedStorage.Packages.Stew)

return function()
	describe('world', function()
		it('should return something', function()
			local world = Stew.world {}
			expect(world).to.be.ok()
		end)

		it('should error if not given a table', function()
			expect(function()
				Stew.world()
			end).to.throw()
		end)

		it('should return a table', function()
			local world = Stew.world {}
			expect(world).to.be.a 'table'
		end)

		it('should contain values in table passed in', function()
			local world = Stew.world { test = 'test' }
			expect(world).to.be.ok()
			expect(world.test).to.be.ok()
			expect(world.test).to.be.a 'string'
		end)

		describe('entity', function()
			it('should create a new number value', function()
				local world = Stew.world {}
				local entity = world.entity()

				expect(entity).to.be.ok()
				expect(entity).to.be.a 'number'
			end)

			it('should increment _nextEntityId by 1', function()
				local world = Stew.world {}

				expect(world._nextEntityId).to.equal(-1)
				world.entity()
				expect(world._nextEntityId).to.equal(0)
			end)
		end)

		describe('tag', function()
			it('should return something', function()
				local world = Stew.world {}
				local tag = world.tag {}
				expect(tag).to.be.ok()
			end)

			it('should error if called without a table', function()
				local world = Stew.world {}
				expect(function()
					world.tag()
				end).to.throw()
			end)

			it('should contain all factory methods', function()
				local world = Stew.world {}
				local tag = world.tag {}

				expect(tag.add).to.be.ok()
				expect(tag.get).to.be.ok()
				expect(tag.remove).to.be.ok()
				expect(tag.added).to.be.ok()
				expect(tag.removed).to.be.ok()
			end)
		end)
	end)
end
