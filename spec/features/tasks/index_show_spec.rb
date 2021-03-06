require 'rails_helper'
RSpec.describe '登録したタスクを確認する', type: :feature, js: true do
  let!(:current_user) { FactoryBot.create(:user) }

  before do
    visit login_path
    fill_in User.human_attribute_name(:email),    with: current_user.email
    fill_in User.human_attribute_name(:password), with: 'password'
    click_button I18n.t('user_sessions.new.submit')
  end

  describe 'タスク一覧' do
    describe '一覧表示' do
      let!(:task1) { FactoryBot.create(:task, title: 'タイトル1', user: current_user, owner: current_user) }
      let!(:task2) { FactoryBot.create(:task, title: 'タイトル2', user: current_user, owner: current_user) }
      let!(:task3) { FactoryBot.create(:task, title: 'タイトル3', user: current_user, owner: current_user) }

      before { visit tasks_path }

      it 'タスクの一覧が表示されること' do
        expect(page).to have_content task1.title
        expect(page).to have_content task2.title
        expect(page).to have_content task3.title
      end
    end

    describe '期限切れのアラート表示' do
      let!(:expired_task) { FactoryBot.create(:task, title: 'タイトル_期限切れ', deadline: Time.current, user: current_user, owner: current_user) }
      before { Timecop.travel(1.day.since) }
      after { Timecop.return }

      it '期限切れタスクがアラートで表示されること' do
        visit tasks_path
        within find('div.alert.alert-warning') do
          expect(page).to have_content expired_task.title
        end
      end
    end

    describe 'ラベル' do
      let!(:task_with_label) { FactoryBot.create(:task, :with_label, user: current_user, owner: current_user) }
      before { visit tasks_path }

      it '紐づくラベルが表示されること' do
        labels = task_with_label.labels.pluck(:name)
        labels.each { |label| expect(page).to have_content label }
      end
    end

    describe 'タスク検索' do
      let!(:now) { Time.current }
      let!(:task1) { FactoryBot.create(:task, :low,    :done,  title: 'タイトル1', deadline: now.since(1.day),  user: current_user, owner: current_user) }
      let!(:task2) { FactoryBot.create(:task, :medium, :doing, title: 'タイトル2', deadline: now.since(2.days), user: current_user, owner: current_user) }
      let!(:task3) { FactoryBot.create(:task, :high,   :todo,  title: 'タイトル3', deadline: now.since(3.days), user: current_user, owner: current_user) }

      before do
        visit tasks_path
        fill_in Task.human_attribute_name(:title), with: task1.title
        select Task.statuses_i18n[task1.status], from: Task.human_attribute_name(:status)
        click_button I18n.t('common.search')
      end

      it 'タイトルとステータスでタスクの検索が行えること' do
        expect(page).to have_content task1.title
        expect(page).to_not have_content task2.title
        expect(page).to_not have_content task3.title
      end

      it '検索後も入力値が保持されること' do
        expect(page).to have_field Task.human_attribute_name(:title), with: task1.title
        expect(page).to have_select Task.human_attribute_name(:status), selected: Task.statuses_i18n[task1.status]
      end
    end

    describe 'タスクの並び替え' do
      let!(:now) { Time.current }
      let!(:task1) { FactoryBot.create(:task, :low,    :done,  title: 'タイトル1', deadline: now.since(1.day),  user: current_user, owner: current_user) }
      let!(:task2) { FactoryBot.create(:task, :medium, :doing, title: 'タイトル2', deadline: now.since(2.days), user: current_user, owner: current_user) }
      let!(:task3) { FactoryBot.create(:task, :high,   :todo,  title: 'タイトル3', deadline: now.since(3.days), user: current_user, owner: current_user) }

      before { visit tasks_path }

      it '期限の降順で並び替えが行えること' do
        within(all('thead th')[4]) do
          click_button '▼'
        end
        expect(all('tbody tr')[0]).to have_content task3.title
        expect(all('tbody tr')[1]).to have_content task2.title
        expect(all('tbody tr')[2]).to have_content task1.title
      end

      it '期限の昇順で並び替えが行えること' do
        within(all('thead th')[4]) do
          click_button '▲'
        end
        expect(all('tbody tr')[0]).to have_content task1.title
        expect(all('tbody tr')[1]).to have_content task2.title
        expect(all('tbody tr')[2]).to have_content task3.title
      end

      it '重要度の降順で並び替えが行えること' do
        within(all('thead th')[3]) do
          click_button '▼'
        end
        expect(all('tbody tr')[0]).to have_content task3.title
        expect(all('tbody tr')[1]).to have_content task2.title
        expect(all('tbody tr')[2]).to have_content task1.title
      end

      it '重要度の昇順で並び替えが行えること' do
        within(all('thead th')[3]) do
          click_button '▲'
        end
        expect(all('tbody tr')[0]).to have_content task1.title
        expect(all('tbody tr')[1]).to have_content task2.title
        expect(all('tbody tr')[2]).to have_content task3.title
      end
    end
  end

  describe 'タスク詳細' do
    let!(:task_with_label) { FactoryBot.create(:task, :with_label, owner: current_user) }
    before { visit task_path(task_with_label) }

    it '指定したタスクの詳細が表示されること' do
      expect(page).to have_content task_with_label.title
    end

    it 'ラベルが表示されること' do
      labels = task_with_label.labels.pluck(:name)
      labels.each { |label| expect(page).to have_content label }
    end
  end
end
